//
//  TearStackView.swift
//  himekuri
//
//  The pad on the wall: binding, stack, the page you pull, and pages falling.
//

import SpriteKit
import SwiftUI

// MARK: - Root view

struct ContentView: View {
    @AppStorage(PageTheme.defaultsKey) private var themeRaw = 0
    @State private var store = CalendarStore()
    @State private var drag: CGSize = .zero
    @State private var hold: CGFloat = 0
    @State private var dragging = false
    @State private var grabX: CGFloat = Metrics.pageW * 0.7
    @State private var grabY: CGFloat = Metrics.pageH * 0.9
    @State private var lastTickLevel = 0
    @State private var catchingUp = false
    /// The page came off mid-drag; swallow the rest of the gesture.
    @State private var tornMidDrag = false
    /// Hand speed at the last gesture event — the throw the freed page inherits.
    @State private var lastVelocity: CGSize = .zero
    /// The paper solver and the SpriteKit scene that warps the page with it.
    @State private var sim = PaperSim()
    @State private var paperScene = PaperScene(size: CGSize(
        width: Metrics.pageW + 2 * Metrics.shaderPadX,
        height: Metrics.pageH + Metrics.shaderPadBottom
    ))
    /// Fraction of the seam already torn. Fibers don't reattach: every pull
    /// leaves lasting damage, and the page can rest half-torn between pulls.
    @State private var damage: CGFloat = 0
    /// Where along the width the seam started parting (page coords).
    @State private var tearCenterX: CGFloat = Metrics.pageW * 0.7

    /// Upward travel needed to flip the sheet fully over the staples —
    /// grab near the bottom and there's a long way to lift; near the top, less.
    private var upSpan: CGFloat {
        max(0.95 * (grabY - Metrics.tearY), 110)
    }

    /// Tension of the current pull, as a fraction of a full tear. Stress
    /// focuses at the crack tip, so existing damage amplifies every pull.
    private var liveTearProgress: CGFloat {
        guard store.canTear else { return 0 }
        let pulled = max(max(drag.height / Metrics.tearThreshold,
                             -drag.height / upSpan), 0)
        return pulled * (1 + 0.8 * damage)
    }

    /// How far (in points from the seam center) fibers have parted right now.
    /// Scaled so the seam spans the page exactly when the crack runs away.
    private var tornFront: CGFloat {
        min((damage + liveTearProgress) / 0.95, 1)
            * (max(tearCenterX, Metrics.pageW - tearCenterX) + 90)
    }

    var body: some View {
        ZStack(alignment: .top) {
            padBlock
                .padding(.top, Metrics.blockTopPad)
        }
        .frame(width: Metrics.windowW, height: Metrics.windowH, alignment: .top)
        .onAppear {
            store.refreshToday()
            paperScene.sim = sim
            refreshPageTexture()
            Task {
                try? await Task.sleep(for: .seconds(1.0))
                catchUpIfNeeded()
            }
        }
        .onChange(of: store.topDate) { refreshPageTexture() }
        .onChange(of: themeRaw) { refreshPageTexture() }
        .onReceive(NotificationCenter.default.publisher(for: .NSCalendarDayChanged)) { _ in
            store.refreshToday()
            catchUpIfNeeded()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            store.refreshToday()
        }
        .onReceive(NotificationCenter.default.publisher(for: .himekuriResetToToday)) { _ in
            store.resetToToday()
            damage = 0
        }
    }

    // MARK: - The pad

    private var theme: PageTheme { PageTheme(rawValue: themeRaw) ?? .showa }

    private var padBlock: some View {
        ZStack(alignment: .top) {
            // Soft shadow the whole object casts on the wall.
            RoundedRectangle(cornerRadius: 3)
                .fill(Color.black.opacity(0.30))
                .frame(width: Metrics.pageW, height: Metrics.pageH)
                .offset(x: 6, y: Metrics.pageTopInset + 14)
                .blur(radius: 16)

            padStack

            PageView(info: store.nextInfo, theme: theme)
                // Recessed in the stack and shaded by the sheet above: without
                // this the revealed page reads as a bright copy of the top one.
                .overlay(
                    LinearGradient(stops: [
                        .init(color: .black.opacity(0.11), location: 0),
                        .init(color: .black.opacity(0.05), location: 0.45),
                        .init(color: .black.opacity(0.08), location: 1),
                    ], startPoint: .top, endPoint: .bottom)
                    .allowsHitTesting(false)
                )
                .padding(.top, Metrics.pageTopInset)

            // Shadow the bowing sheet casts onto the page beneath: it deepens
            // and spreads with tension rather than travelling downward. When
            // lifting, the shadow climbs with the swinging sheet instead.
            if abs(drag.height) > 2 {
                let p = min(abs(drag.height) / 110, 1)
                let up = drag.height < 0
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.black.opacity(0.24 * p))
                    .frame(width: Metrics.pageW - 20, height: 110 + 60 * p)
                    .offset(x: drag.width * 0.25,
                            y: Metrics.pageTopInset + Metrics.pageH - 130 + (up ? -60 * p : 10 * p))
                    .blur(radius: 14 + 10 * p)
                    .allowsHitTesting(false)
            }

            // The top page: a printed texture warped by the paper solver.
            SpriteView(scene: paperScene, options: [.allowsTransparency])
                .frame(width: Metrics.pageW + 2 * Metrics.shaderPadX,
                       height: Metrics.pageH + Metrics.shaderPadBottom)
                .padding(.top, Metrics.pageTopInset)
                .allowsHitTesting(false)

            // A half-torn seam: parted fibers catch the light where the last
            // pull left off, and stay parted until the page comes away.
            if damage > 0.03 {
                TearEdgeLine(seed: tearSeed(for: store.tornCount))
                    .stroke(Color.white.opacity(0.55), lineWidth: 0.7)
                    .frame(width: Metrics.pageW, height: 36)
                    .mask {
                        Rectangle()
                            .frame(width: max(tornFront * 2 - 36, 0), height: 36)
                            .blur(radius: 16)
                            .position(x: tearCenterX, y: 18)
                    }
                    .padding(.top, Metrics.pageTopInset)
                    .allowsHitTesting(false)
            }

            // Remnants under the staples: slivers of the same paper, layered.
            if store.tornCount > 0 {
                let lastSeed = tearSeed(for: store.tornCount - 1)
                ZStack(alignment: .top) {
                    // An older, slightly deeper sliver peeking out beneath.
                    if store.tornCount > 1 {
                        StubShape(seed: tearSeed(for: store.tornCount - 2))
                            .fill(theme.paper.mix(with: theme.edge, by: 0.5))
                            .offset(y: 1.4)
                    }
                    StubShape(seed: lastSeed)
                        .fill(theme.paper.mix(with: theme.edge, by: 0.15))
                        .shadow(color: .black.opacity(0.10), radius: 1.4, y: 1)
                    // Loose fibers catch the light along the torn edge.
                    TearEdgeLine(seed: lastSeed)
                        .stroke(Color.white.opacity(0.5), lineWidth: 0.7)
                }
                .frame(width: Metrics.pageW, height: 36)
                .padding(.top, Metrics.pageTopInset)
                .allowsHitTesting(false)
            }

            binding

            tearHitLayer
        }
        .frame(
            width: Metrics.pageW + 2 * Metrics.shaderPadX,
            height: Metrics.pageH + 60,
            alignment: .top
        )
    }

    /// The unturned pages beneath, thicker while the year is young.
    private var padStack: some View {
        let layers = max(4, Int(store.remainingFraction * 22))
        return ZStack(alignment: .top) {
            ForEach(0..<layers, id: \.self) { i in
                let depth = CGFloat(layers - i)
                RoundedRectangle(cornerRadius: 2)
                    .fill(theme.paper.mix(with: theme.edge, by: Double(depth) / Double(layers) * 0.9))
                    .frame(width: Metrics.pageW, height: Metrics.pageH)
                    .offset(x: depth * 0.55, y: Metrics.pageTopInset + depth * 0.85)
            }
        }
        .allowsHitTesting(false)
    }

    private var binding: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 3)
                .fill(LinearGradient(
                    colors: [Color(white: 0.985), Color(white: 0.86)],
                    startPoint: .top, endPoint: .bottom))
                .overlay(
                    RoundedRectangle(cornerRadius: 3)
                        .strokeBorder(Color.black.opacity(0.12), lineWidth: 0.5))
                .overlay(alignment: .top) {
                    // The vermilion spine tape peeking over the top.
                    Rectangle()
                        .fill(Ink.vermilion.opacity(0.9))
                        .frame(height: 2.5)
                        .padding(.horizontal, 2)
                        .padding(.top, 0.5)
                }
            HStack {
                staple
                Spacer()
                hangingHole
                Spacer()
                staple
            }
            .padding(.horizontal, 46)
        }
        .frame(width: Metrics.pageW + 10, height: Metrics.bindingH)
        .shadow(color: .black.opacity(0.18), radius: 2, y: 1.5)
        // The binding is the handle: drag it to move the pad around the desk.
        .contentShape(Rectangle())
        .gesture(WindowDragGesture())
    }

    private var staple: some View {
        RoundedRectangle(cornerRadius: 1)
            .fill(LinearGradient(
                colors: [Color(white: 0.55), Color(white: 0.75), Color(white: 0.45)],
                startPoint: .top, endPoint: .bottom))
            .frame(width: 16, height: 3.5)
    }

    private var hangingHole: some View {
        Circle()
            .fill(Color.black.opacity(0.32))
            .overlay(Circle().strokeBorder(Color.black.opacity(0.35), lineWidth: 1))
            .frame(width: 9, height: 9)
    }

    // MARK: - Tear gesture

    /// Invisible layer over the lower two-thirds of the page.
    private var tearHitLayer: some View {
        Color.clear
            .frame(width: Metrics.pageW, height: Metrics.pageH * Metrics.tearZone)
            .contentShape(Rectangle())
            .gesture(tearGesture)
            .onHover { inside in
                (inside ? NSCursor.openHand : NSCursor.arrow).set()
            }
            .padding(.top, Metrics.pageTopInset + Metrics.pageH * (1 - Metrics.tearZone))
    }

    private var tearGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                if tornMidDrag { return }
                if !dragging {
                    dragging = true
                    grabX = min(max(value.startLocation.x, 0), Metrics.pageW)
                    // The hit layer covers the lower part of the page.
                    grabY = Metrics.pageH * (1 - Metrics.tearZone) + value.startLocation.y
                    // An untouched seam starts parting wherever you grab;
                    // a damaged one keeps tearing from where it left off.
                    if damage < 0.02 { tearCenterX = grabX }
                    lastTickLevel = Int(damage * 4)
                    sim.setGrab(at: CGPoint(x: grabX, y: grabY))
                    NSCursor.closedHand.set()
                    // The sheet reacts to the touch itself: a pinch puckers in
                    // under the fingers before any pulling happens.
                    withAnimation(.spring(response: 0.22, dampingFraction: 0.62)) {
                        hold = 1
                    }
                    TearSound.shared.playRustle()
                }
                let dy = value.translation.height
                // Pulling down bows the sheet out — it resists, so travel
                // saturates. Lifting is the flip: the sheet folds over freely
                // and follows the hand until the fibers give.
                let y: CGFloat
                if dy >= 0 {
                    let capDown: CGFloat = store.canTear ? 190 : 26
                    y = capDown * tanh(dy / capDown)
                } else if store.canTear {
                    y = dy
                } else {
                    y = -20 * tanh(-dy / 20) // tomorrow refuses politely
                }
                let x = 70 * tanh(value.translation.width / 70)
                drag = CGSize(width: x, height: y)
                lastVelocity = value.velocity

                // The solver gets the RAW hand position: inextensibility is
                // its job, so the paper goes taut on its own, not via caps.
                sim.moveGrab(
                    to: CGPoint(x: grabX + value.translation.width,
                                y: grabY + value.translation.height),
                    lift: hold
                )
                sim.setSeam(centerX: tearCenterX, front: tornFront)

                // Crackles and haptic ticks as fibers give way — picking up
                // from however much of the seam is already parted. Damage
                // amplifies the pull: stress focuses at the crack tip.
                let pulled = max(y / Metrics.tearThreshold, -y / upSpan)
                let progress = damage + max(pulled, 0) * (1 + 0.8 * damage)

                // Past this point the crack RUNS AWAY — each fiber's failure
                // overloads the next, and the page comes off in the hand.
                if store.canTear, progress >= 0.95 {
                    tornMidDrag = true
                    performTear()
                    return
                }

                let level = Int(min(progress / 0.95, 1) * 4)
                if store.canTear, level > lastTickLevel, level > 0 {
                    lastTickLevel = level
                    Haptics.tick()
                    TearSound.shared.playCrackle(intensity: Float(min(progress, 1)))
                }
            }
            .onEnded { value in
                dragging = false
                lastTickLevel = 0
                NSCursor.openHand.set()
                sim.release()
                if tornMidDrag {
                    tornMidDrag = false
                    return
                }
                let flickDown = drag.height > 60 && value.predictedEndTranslation.height > 240
                let flickUp = drag.height < -50 && value.predictedEndTranslation.height < -260
                let pulled = max(drag.height / Metrics.tearThreshold,
                                 -drag.height / upSpan)
                let amplified = max(pulled, 0) * (1 + 0.8 * damage)
                if store.canTear, damage + amplified >= 0.95 || flickDown || flickUp {
                    performTear()
                } else {
                    if store.canTear, pulled > 0.15 {
                        // Fibers that parted stay parted: the pull leaves
                        // lasting damage and the page can rest half-torn.
                        damage = min(damage + amplified * 0.7, 0.8)
                        TearSound.shared.playCrackle(intensity: Float(pulled) * 0.5)
                    }
                    if !store.canTear, abs(drag.height) > 12 {
                        Haptics.tick() // tomorrow refuses politely
                    }
                    withAnimation(.spring(response: 0.45, dampingFraction: 0.55)) {
                        drag = .zero
                        hold = 0
                    }
                    // The solver keeps only the lasting damage once released.
                    sim.setSeam(
                        centerX: tearCenterX,
                        front: min(damage / 0.95, 1)
                            * (max(tearCenterX, Metrics.pageW - tearCenterX) + 90)
                    )
                }
            }
    }

    /// Prints the current top page into the texture the solver warps.
    private func refreshPageTexture() {
        let renderer = ImageRenderer(content: PageView(info: store.topInfo, theme: theme))
        renderer.scale = 2
        if let cg = renderer.cgImage {
            paperScene.setPageTexture(SKTexture(cgImage: cg))
        }
    }

    // MARK: - Tearing

    /// Irreversible. The page comes off, falls past the bottom of the screen, and is gone.
    private func performTear() {
        // The sheet never travelled far during the pull (paper doesn't stretch),
        // so the freed piece starts from the small real give, not the full drag.
        let upward = drag.height < 0 || lastVelocity.height < -200
        let piece = FallingPage(
            info: store.topInfo,
            theme: theme,
            seed: tearSeed(for: store.tornCount),
            // An upward tear frees the sheet where the roll was, not at rest.
            start: CGSize(
                width: drag.width * 0.3,
                height: upward ? max(drag.height * 0.55, -140) : min(drag.height * 0.15, 16)
            ),
            grabX: grabX,
            upward: upward,
            throwVelocity: lastVelocity
        )
        TearSound.shared.playRip()
        Haptics.rip()
        FallingPageOverlay.spawn(piece)

        // Swap the pages with no implicit animation — the falling piece covers it.
        var tx = Transaction()
        tx.disablesAnimations = true
        withTransaction(tx) {
            store.tear()
            drag = .zero
            hold = 0
            damage = 0
        }
        sim.reset()
    }

    /// Auto-tear at midnight (opt-in): tears everything older than today.
    private func catchUpIfNeeded() {
        guard UserDefaults.standard.bool(forKey: "himekuri.autoTear"), !catchingUp else { return }
        catchingUp = true
        Task {
            while store.topDate < store.today {
                grabX = Metrics.pageW * 0.7
                lastVelocity = CGSize(width: 30, height: 380)
                sim.setGrab(at: CGPoint(x: grabX, y: grabY))
                sim.moveGrab(to: CGPoint(x: grabX + 18, y: grabY + 132), lift: 1)
                withAnimation(.easeIn(duration: 0.55)) {
                    drag = CGSize(width: 18, height: 132)
                    hold = 1
                }
                try? await Task.sleep(for: .seconds(0.6))
                performTear()
                try? await Task.sleep(for: .seconds(1.5))
            }
            catchingUp = false
        }
    }
}

// MARK: - Pull distortion

/// Animatable so the snap-back spring interpolates through the shader.
struct PaperPull: ViewModifier, Animatable {
    var pull: CGSize
    var hold: CGFloat
    var grabX: CGFloat
    var grabY: CGFloat
    var tearCenterX: CGFloat = 0
    var tornFront: CGFloat = 0
    var paper: Color = Ink.paper

    var animatableData: AnimatablePair<CGFloat, AnimatablePair<CGFloat, CGFloat>> {
        get { AnimatablePair(pull.width, AnimatablePair(pull.height, hold)) }
        set {
            pull = CGSize(width: newValue.first, height: newValue.second.first)
            hold = newValue.second.second
        }
    }

    func body(content: Content) -> some View {
        let layerW = Metrics.pageW + 2 * Metrics.shaderPadX
        let layerH = Metrics.pageH + Metrics.shaderPadBottom
        // Downward/sideways tension bows the sheet (the roll of an upward
        // lift is lit inside the shader instead).
        let pDown = min(hypot(pull.width, max(pull.height, 0)) / 110, 1)
        // Visible pressing: a bare whisper on hold, deepening with the pull —
        // a resting sheet barely shows a touch; tension is what shows.
        let press = min(hold * 0.35 + pDown * 0.80, 1)
        content
            // Curl lighting, applied before the distortion so it bends with
            // the sheet: a shadow rolling into the crest, then a highlight.
            .overlay(
                LinearGradient(stops: [
                    .init(color: .clear, location: 0.50),
                    .init(color: .black.opacity(0.14 * pDown), location: 0.80),
                    .init(color: .black.opacity(0.03 * pDown), location: 0.90),
                    .init(color: .white.opacity(0.16 * pDown), location: 0.965),
                    .init(color: .clear, location: 1.0),
                ], startPoint: .top, endPoint: .bottom)
                .allowsHitTesting(false)
            )
            // Cone lighting, also pre-distortion. Paper pulled from a point
            // cones around the taut staple-to-fingers line: a soft sheen
            // runs along that line, and the sheet shades where it bends
            // away just past the grab. One smooth surface — no spokes.
            .overlay(
                ZStack {
                    Rectangle()
                        .fill(LinearGradient(
                            colors: [.clear, .white.opacity(0.09), .clear],
                            startPoint: .leading, endPoint: .trailing))
                        .frame(width: 110, height: max(grabY - Metrics.tearY, 1))
                        .mask(LinearGradient(colors: [.clear, .white],
                                             startPoint: .top, endPoint: .bottom))
                        .position(x: grabX, y: (Metrics.tearY + grabY) / 2)
                    RadialGradient(colors: [.black.opacity(0.07), .clear],
                                   center: .center, startRadius: 8, endRadius: 90)
                        .frame(width: 190, height: 150)
                        .position(x: grabX, y: grabY + 26)
                }
                .opacity(Double(press))
                .allowsHitTesting(false)
            )
            .padding(.horizontal, Metrics.shaderPadX)
            .padding(.bottom, Metrics.shaderPadBottom)
            .layerEffect(
                ShaderLibrary.paperSheet(
                    .float2(layerW, layerH),
                    .float2(grabX + Metrics.shaderPadX, grabY),
                    .float2(pull.width, pull.height),
                    .float(Metrics.tearY),
                    .float(hold),
                    .float2(tearCenterX + Metrics.shaderPadX, tornFront),
                    .color(paper)
                ),
                maxSampleOffset: CGSize(width: 90, height: 480),
                isEnabled: pull != .zero || hold > 0.001 || tornFront >= 1
            )
    }

}

// MARK: - Falling page model

struct FallingPage: Identifiable {
    let id = UUID()
    let info: DayInfo
    let theme: PageTheme
    let seed: UInt64
    let start: CGSize
    let grabX: CGFloat
    /// Torn by an upward flick: the piece is flung over the staples first.
    let upward: Bool
    /// Hand speed at the moment the fibers gave — the throw it inherits.
    let throwVelocity: CGSize
}
