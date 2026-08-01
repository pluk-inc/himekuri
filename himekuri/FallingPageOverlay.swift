//
//  FallingPageOverlay.swift
//  himekuri
//
//  A torn page falls in its own transparent, click-through window that spans
//  from the pad down to the bottom edge of the screen, so it drifts past
//  everything and slips off the display instead of being clipped or faded.
//

import AppKit
import SwiftUI

@MainActor
enum FallingPageOverlay {
    /// Horizontal breathing room for the flutter swings plus a thrown carry.
    private static let margin: CGFloat = 300

    static func spawn(_ piece: FallingPage) {
        guard let main = NSApp.windows.first(where: { $0 is PaperWindow }),
              let screen = main.screen ?? NSScreen.main else { return }

        let top = main.frame.maxY
        let bottom = screen.frame.minY
        // A piece flung upward needs air above the pad before it falls.
        let headroom: CGFloat = piece.upward ? min(300, max(screen.visibleFrame.maxY - top, 0)) : 0
        let height = top + headroom - bottom
        guard height > 100 else { return }

        let frame = NSRect(
            x: main.frame.minX - margin,
            y: bottom,
            width: Metrics.windowW + 2 * margin,
            height: height
        )

        let window = NSWindow(
            contentRect: frame,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = false
        window.ignoresMouseEvents = true
        window.isReleasedWhenClosed = false
        window.level = main.level
        window.collectionBehavior = main.collectionBehavior

        // Distance from the page's resting spot to fully past the screen bottom.
        let distance = (top - bottom) - Metrics.blockTopPad - Metrics.pageTopInset + 60
        let host = NSHostingView(
            rootView: FallingPageView(page: piece, fallDistance: distance, headroom: headroom)
        )
        host.frame = NSRect(origin: .zero, size: frame.size)
        window.contentView = host

        main.addChildWindow(window, ordered: .above)
        window.orderFront(nil)

        Task {
            try? await Task.sleep(for: .seconds(3.4))
            main.removeChildWindow(window)
            window.orderOut(nil)
            window.contentView = nil
        }
    }
}

// MARK: - The fall

nonisolated struct FallState {
    var x: Double
    var y: Double
    var rot: Double   // z-rotation, degrees
    var tilt: Double  // 3D planing tilt, degrees
}

struct FallingPageView: View {
    let page: FallingPage
    let fallDistance: CGFloat
    var headroom: CGFloat = 0
    @State private var go = false

    private var dir: Double { page.grabX < Metrics.pageW / 2 ? -1 : 1 }

    /// How high an upward-flicked piece rises before gravity wins.
    private var rise: Double { Double(max(min(headroom - 40, 210), 0)) }

    var body: some View {
        ZStack(alignment: .top) {
            TimelineView(.animation) { timeline in
                let t = timeline.date.timeIntervalSinceReferenceDate
                KeyframeAnimator(
                    initialValue: FallState(
                        x: page.start.width,
                        y: page.start.height,
                        rot: dir * 1.5,
                        tilt: page.upward ? 12 : 2
                    ),
                    trigger: go
                ) { v in
                    // Farther from the wall: softer, fainter, lower shadow.
                    let depth = min(max(v.y / Double(fallDistance), 0), 1)
                    PageView(info: page.info, theme: page.theme)
                        .clipShape(TornPieceShape(seed: page.seed))
                        // The sheet is not rigid — it ripples as it planes.
                        .padding(14)
                        .distortionEffect(
                            ShaderLibrary.paperFlex(
                                .float2(Metrics.pageW + 28, Metrics.pageH + 28),
                                .float(t.truncatingRemainder(dividingBy: 1000)),
                                .float(3.0)
                            ),
                            maxSampleOffset: CGSize(width: 0, height: 14)
                        )
                        .compositingGroup()
                        .shadow(
                            color: .black.opacity(0.30 - 0.18 * depth),
                            radius: 9 + 16 * depth,
                            y: 7 + 20 * depth
                        )
                        .rotation3DEffect(
                            .degrees(v.tilt),
                            axis: (x: 1, y: 0.15 * dir, z: 0),
                            anchor: .center,
                            perspective: 0.25
                        )
                        .rotationEffect(.degrees(v.rot), anchor: .center)
                        .offset(x: v.x, y: v.y)
                } keyframes: { _ in
                    fallKeyframes()
                }
            }
            .padding(.top, headroom + Metrics.blockTopPad + Metrics.pageTopInset - 14)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .onAppear { go = true }
        .allowsHitTesting(false)
    }

    /// Paper doesn't free-fall: it lets go slowly, reaches a drifting terminal
    /// speed, and sways side to side, planing on the air as it goes.
    /// A piece torn by an upward flick keeps that momentum: it sails up past
    /// the staples, stalls at the top of its arc, then flutters down.
    @KeyframesBuilder<FallState>
    private func fallKeyframes() -> some Keyframes<FallState> {
        let d = Double(fallDistance)
        let x0 = page.start.width
        let y0 = page.start.height
        let up = page.upward
        // The throw: whatever direction and speed the hand had when the
        // fibers gave, the freed sheet inherits (clamped to plausible speeds).
        let vx = Double(max(min(page.throwVelocity.width, 650), -650))
        let vy = Double(max(min(page.throwVelocity.height, 1800), -2400))
        let dirT: Double = abs(vx) > 80 ? (vx > 0 ? 1 : -1) : dir

        // Ballistic apex from the launch speed (v²/2g), capped by the air
        // available above the pad; light paper stalls fast, so g is generous.
        let apex = up ? min(max(vy * vy / 6400.0, 70), rise) : 0
        let tUp = up ? max(min(2 * apex / max(-vy, 260), 0.5), 0.16) : 0
        // Sideways carry from the throw, damped by air drag.
        let carry = vx * (up ? tUp : 0.30) * 0.7
        // Once falling, paper descends STEADILY at terminal speed — it sways
        // sideways but never hangs or bobs, so y only ever accelerates.
        KeyframeTrack(\.y) {
            CubicKeyframe(up ? y0 - apex : y0 + min(max(70, vy * 0.22), d * 0.25),
                          duration: up ? tUp : 0.30)
            CubicKeyframe(up ? y0 - apex * 0.84 : d * 0.30, duration: up ? 0.22 : 0.42)
            CubicKeyframe(up ? d * 0.38 : d * 0.63, duration: up ? 0.55 : 0.44)
            CubicKeyframe(d * 1.00, duration: up ? 0.52 : 0.46)
        }
        KeyframeTrack(\.x) {
            CubicKeyframe(x0 + carry + (up ? 8 : 26) * dirT, duration: up ? tUp : 0.35)
            CubicKeyframe(x0 + carry * 1.25 + (up ? 26 : -38) * dirT, duration: up ? 0.26 : 0.60)
            CubicKeyframe(x0 + carry * 1.05 + (up ? -22 : 48) * dirT, duration: up ? 0.68 : 0.60)
            CubicKeyframe(x0 + carry * 0.9 + (up ? 24 : -20) * dirT, duration: up ? 0.70 : 0.55)
        }
        // The sheet banks gently against its sideways drift.
        KeyframeTrack(\.rot) {
            CubicKeyframe(dirT * (up ? 5 : -3), duration: 0.40)
            CubicKeyframe(dirT * (up ? -4 : 4), duration: 0.60)
            CubicKeyframe(dirT * (up ? -6 : -5), duration: 0.60)
            CubicKeyframe(dirT * (up ? 4 : 3), duration: 0.50)
        }
        // A whisper of planing — near-constant so the projection doesn't
        // breathe (a growing/shrinking page reads as rising and sinking).
        KeyframeTrack(\.tilt) {
            CubicKeyframe(up ? 14 : 8, duration: 0.40)
            CubicKeyframe(up ? 7 : 6, duration: 0.55)
            CubicKeyframe(9, duration: 0.60)
            CubicKeyframe(7, duration: 0.55)
        }
    }
}
