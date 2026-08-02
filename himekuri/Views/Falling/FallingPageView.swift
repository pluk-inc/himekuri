//
//  FallingPageView.swift
//  himekuri
//
//  The freed sheet in flight. Paper at terminal speed only accelerates —
//  it sways and banks, but never bobs, and never flips.
//

import SwiftUI

struct FallingPageView: View {
    let page: FallingPage
    let fallDistance: CGFloat
    let headroom: CGFloat
    @State private var go = false
    /// When this sheet was let go — the clock the hand-run path reads from.
    @State private var start = Date()

    /// Which way the sheet leans when the hand gave it no sideways speed.
    private let dir: Double
    /// Worked out once rather than per frame: the body re-runs every tick.
    private let plan: FallPlan

    init(page: FallingPage, fallDistance: CGFloat, headroom: CGFloat = 0) {
        self.page = page
        self.fallDistance = fallDistance
        self.headroom = headroom
        let dir: Double = page.grabX < Metrics.pageW / 2 ? -1 : 1
        // How high an upward-flicked piece rises before gravity wins.
        let rise = Double(max(min(headroom - 40, 210), 0))
        self.dir = dir
        self.plan = FallPlan.make(page: page, fallDistance: fallDistance, dir: dir, rise: rise)
    }

    var body: some View {
        ZStack(alignment: .top) {
            TimelineView(.animation) { timeline in
                let t = timeline.date.timeIntervalSinceReferenceDate
                if #available(macOS 14.0, *) {
                    // SwiftUI drives the waypoints and the paper ripples.
                    KeyframeAnimator(initialValue: plan.initialState, trigger: go) { v in
                        sheet(v, rippleTime: t)
                    } keyframes: { _ in
                        keyframes(plan)
                    }
                } else {
                    // Same waypoints, interpolated by hand off the timeline.
                    sheet(plan.state(at: timeline.date.timeIntervalSince(start)), rippleTime: nil)
                }
            }
            .padding(.top, headroom + Metrics.blockTopPad + Metrics.pageTopInset - 14)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .onAppear {
            start = Date()
            go = true
        }
        .allowsHitTesting(false)
    }

    /// The sheet itself at one instant of the flight.
    private func sheet(_ v: FallState, rippleTime: Double?) -> some View {
        // Farther from the wall: softer, fainter, lower shadow.
        let depth = min(max(v.y / Double(fallDistance), 0), 1)
        return PageView(info: page.info, theme: page.theme)
            .clipShape(TornPieceShape(seed: page.seed))
            // The sheet is not rigid — it ripples as it planes.
            .padding(14)
            .modifier(PaperFlex(time: rippleTime))
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
                perspective: 0.45
            )
            .rotationEffect(.degrees(v.rot), anchor: .center)
            .offset(x: v.x, y: v.y)
    }

    @available(macOS 14.0, *)
    @KeyframesBuilder<FallState>
    private func keyframes(_ plan: FallPlan) -> some Keyframes<FallState> {
        KeyframeTrack(\.y) { track(plan.y) }
        KeyframeTrack(\.x) { track(plan.x) }
        KeyframeTrack(\.rot) { track(plan.rot) }
        KeyframeTrack(\.tilt) { track(plan.tilt) }
    }

    @available(macOS 14.0, *)
    @KeyframeTrackContentBuilder<Double>
    private func track(_ t: FallTrack) -> some KeyframeTrackContent<Double> {
        for key in t.keys {
            CubicKeyframe(key.value, duration: key.duration)
        }
    }
}

/// The paper's ripple, which needs the Metal shader support added in Sonoma.
/// Without it the sheet simply stays flat as it falls.
private struct PaperFlex: ViewModifier {
    let time: Double?

    func body(content: Content) -> some View {
        if #available(macOS 14.0, *), let time {
            content.distortionEffect(
                ShaderLibrary.paperFlex(
                    .float2(Metrics.pageW + 28, Metrics.pageH + 28),
                    .float(time.truncatingRemainder(dividingBy: 1000)),
                    .float(3.0)
                ),
                maxSampleOffset: CGSize(width: 0, height: 14)
            )
        } else {
            content
        }
    }
}
