//
//  ContentView.swift
//  himekuri
//
//  The pad on the wall: stack, binding, the simulated top page, and the
//  tear gesture with its crack-propagation model.
//

import SpriteKit
import SwiftUI

struct ContentView: View {
    @AppStorage(PageTheme.defaultsKey) private var themeRaw = 0
    @State private var store = CalendarStore()
    @State private var drag: CGSize = .zero
    @State private var hold: CGFloat = 0
    @State private var dragging = false
    @State private var grabX: CGFloat = Metrics.pageW * 0.7
    @State private var grabY: CGFloat = Metrics.pageH * 0.9
    @State private var lastTickLevel = 0
    /// The page came off mid-drag; swallow the rest of the gesture.
    @State private var tornMidDrag = false
    /// Hand speed at the last gesture event — the throw the freed page inherits.
    @State private var lastVelocity: CGSize = .zero
    /// The paper solver and the SpriteKit scene that warps the page with it.
    @State private var sim = PaperSim()
    @State private var paperScene = PaperScene(size: CGSize(
        width: Metrics.pageW + 2 * Metrics.overhangX,
        height: Metrics.pageH + Metrics.overhangBottom
    ))
    /// Fraction of the seam already torn. Fibers don't reattach: every pull
    /// leaves lasting damage, and the page can rest half-torn between pulls.
    @State private var damage: CGFloat = 0
    /// Where along the width the seam started parting (page coords).
    @State private var tearCenterX: CGFloat = Metrics.pageW * 0.7

    private var theme: PageTheme { PageTheme(rawValue: themeRaw) ?? .showa }

    // MARK: - Crack model

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
        min((damage + liveTearProgress) / 0.95, 1) * seamSpan
    }

    /// Distance from the seam center to the farthest column, plus margin.
    private var seamSpan: CGFloat {
        max(tearCenterX, Metrics.pageW - tearCenterX) + 90
    }

    // MARK: - Body

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
        }
        .onChange(of: store.topDate) { refreshPageTexture() }
        .onChange(of: themeRaw) { refreshPageTexture() }
        .onReceive(NotificationCenter.default.publisher(for: .NSCalendarDayChanged)) { _ in
            store.refreshToday()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            store.refreshToday()
        }
        .onReceive(NotificationCenter.default.publisher(for: .himekuriResetToToday)) { _ in
            // Posted only by the dev-build menu item.
            store.resetToToday()
            damage = 0
            sim.reset()
        }
    }

    // MARK: - The pad

    private var padBlock: some View {
        ZStack(alignment: .top) {
            // Soft shadow the whole object casts on the wall.
            RoundedRectangle(cornerRadius: 3)
                .fill(Color.black.opacity(0.30))
                .frame(width: Metrics.pageW, height: Metrics.pageH)
                .offset(x: 6, y: Metrics.pageTopInset + 14)
                .blur(radius: 16)

            PadStack(remainingFraction: store.remainingFraction, theme: theme)

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
                .frame(width: Metrics.pageW + 2 * Metrics.overhangX,
                       height: Metrics.pageH + Metrics.overhangBottom)
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

            if store.tornCount > 0 {
                PadStubs(tornCount: store.tornCount, theme: theme)
                    .padding(.top, Metrics.pageTopInset)
            }

            PadBinding()

            tearHitLayer
        }
        .frame(
            width: Metrics.pageW + 2 * Metrics.overhangX,
            height: Metrics.pageH + 60,
            alignment: .top
        )
    }

    // MARK: - Tear gesture

    /// Invisible layer over the lower part of the page.
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
                if !dragging { beginGrab(at: value.startLocation) }

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
                    settleWithoutTearing(pulled: pulled, amplified: amplified)
                }
            }
    }

    private func beginGrab(at start: CGPoint) {
        dragging = true
        grabX = min(max(start.x, 0), Metrics.pageW)
        // The hit layer covers the lower part of the page.
        grabY = Metrics.pageH * (1 - Metrics.tearZone) + start.y
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

    private func settleWithoutTearing(pulled: CGFloat, amplified: CGFloat) {
        if store.canTear, pulled > 0.15 {
            // Fibers that parted stay parted: the pull leaves lasting
            // damage and the page can rest half-torn.
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
        sim.setSeam(centerX: tearCenterX, front: min(damage / 0.95, 1) * seamSpan)
    }

    // MARK: - Tearing

    /// Prints the current top page into the texture the solver warps.
    private func refreshPageTexture() {
        let renderer = ImageRenderer(content: PageView(info: store.topInfo, theme: theme))
        renderer.scale = 2
        if let cg = renderer.cgImage {
            paperScene.setPageTexture(SKTexture(cgImage: cg))
        }
    }

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
}
