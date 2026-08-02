//
//  FallPlan.swift
//  himekuri
//
//  The flight path of a torn sheet, as plain numbers.
//
//  `KeyframeAnimator` is macOS 14+, so the waypoints live here rather than in
//  a `@KeyframesBuilder`: modern systems hand them to SwiftUI, older ones run
//  the interpolation below. One set of numbers, two ways of playing it.
//

import Foundation

nonisolated struct FallState {
    var x: Double
    var y: Double
    var rot: Double   // z-rotation, degrees
    var tilt: Double  // 3D planing tilt, degrees
}

nonisolated struct FallKey {
    let value: Double
    let duration: Double

    init(_ value: Double, duration: Double) {
        self.value = value
        self.duration = duration
    }
}

/// One animated property: where it starts, and the waypoints it passes through.
nonisolated struct FallTrack {
    let from: Double
    let keys: [FallKey]

    /// Cumulative time of each point (starting at 0 for `from`) and the value
    /// there. Worked out once: the hand-run path asks for a value every frame.
    private let times: [Double]
    private let values: [Double]

    init(from: Double, keys: [FallKey]) {
        self.from = from
        self.keys = keys
        var t = 0.0
        self.times = [0] + keys.map { t += $0.duration; return t }
        self.values = [from] + keys.map(\.value)
    }

    /// Catmull-Rom through the waypoints — the curve shape `CubicKeyframe`
    /// produces, for systems that have to interpolate by hand.
    func value(at time: Double) -> Double {
        let ts = times
        let vs = values
        guard let total = ts.last, total > 0 else { return from }
        if time <= 0 { return from }
        if time >= total { return vs[vs.count - 1] }

        // The segment this instant falls in.
        var i = 0
        while i < ts.count - 2 && time > ts[i + 1] { i += 1 }

        let dt = ts[i + 1] - ts[i]
        guard dt > 0 else { return vs[i + 1] }
        let s = (time - ts[i]) / dt

        let p1 = vs[i]
        let p2 = vs[i + 1]
        // Tangents from the neighbouring points; at either end the curve just
        // leans on the segment itself, which is what stops it overshooting.
        let m1: Double = i > 0
            ? (p2 - vs[i - 1]) / (ts[i + 1] - ts[i - 1]) * dt
            : p2 - p1
        let m2: Double = i + 2 < vs.count
            ? (vs[i + 2] - p1) / (ts[i + 2] - ts[i]) * dt
            : p2 - p1

        let s2 = s * s
        let s3 = s2 * s
        let h00 = 2 * s3 - 3 * s2 + 1
        let h10 = s3 - 2 * s2 + s
        let h01 = -2 * s3 + 3 * s2
        let h11 = s3 - s2
        return h00 * p1 + h10 * m1 + h01 * p2 + h11 * m2
    }
}

/// The whole flight: four tracks played together.
nonisolated struct FallPlan {
    let x: FallTrack
    let y: FallTrack
    let rot: FallTrack
    let tilt: FallTrack

    var initialState: FallState {
        FallState(x: x.from, y: y.from, rot: rot.from, tilt: tilt.from)
    }

    func state(at time: Double) -> FallState {
        FallState(
            x: x.value(at: time),
            y: y.value(at: time),
            rot: rot.value(at: time),
            tilt: tilt.value(at: time)
        )
    }

    /// Paper doesn't free-fall: it lets go slowly, reaches a drifting terminal
    /// speed, and sways side to side, planing on the air as it goes.
    /// A piece torn by an upward flick keeps that momentum: it sails up past
    /// the staples, stalls at the top of its arc, then flutters down.
    ///
    /// - Parameters:
    ///   - dir: which way the sheet leans when the hand gave no sideways speed.
    ///   - rise: how much air there is above the pad for an upward flick.
    static func make(page: FallingPage, fallDistance: CGFloat, dir: Double, rise: Double) -> FallPlan {
        let d = Double(fallDistance)
        let x0 = Double(page.start.width)
        let y0 = Double(page.start.height)
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

        return FallPlan(
            x: FallTrack(from: x0, keys: [
                FallKey(x0 + carry + (up ? 8 : 26) * dirT, duration: up ? tUp : 0.35),
                FallKey(x0 + carry * 1.25 + (up ? 26 : -38) * dirT, duration: up ? 0.26 : 0.60),
                FallKey(x0 + carry * 1.05 + (up ? -22 : 48) * dirT, duration: up ? 0.68 : 0.60),
                FallKey(x0 + carry * 0.9 + (up ? 24 : -20) * dirT, duration: up ? 0.70 : 0.55),
            ]),
            // Once falling, paper descends STEADILY at terminal speed — it
            // sways sideways but never hangs or bobs, so y only accelerates.
            y: FallTrack(from: y0, keys: [
                FallKey(up ? y0 - apex : y0 + min(max(70, vy * 0.22), d * 0.25),
                        duration: up ? tUp : 0.30),
                FallKey(up ? y0 - apex * 0.84 : d * 0.30, duration: up ? 0.22 : 0.42),
                FallKey(up ? d * 0.38 : d * 0.63, duration: up ? 0.55 : 0.44),
                FallKey(d * 1.00, duration: up ? 0.52 : 0.46),
            ]),
            // The sheet banks gently against its sideways drift.
            rot: FallTrack(from: dir * 1.5, keys: [
                FallKey(dirT * (up ? 5 : -3), duration: 0.40),
                FallKey(dirT * (up ? -4 : 4), duration: 0.60),
                FallKey(dirT * (up ? -6 : -5), duration: 0.60),
                FallKey(dirT * (up ? 4 : 3), duration: 0.50),
            ]),
            // A whisper of planing — near-constant so the projection doesn't
            // breathe (a growing/shrinking page reads as rising and sinking).
            tilt: FallTrack(from: up ? 12 : 2, keys: [
                FallKey(up ? 14 : 8, duration: 0.40),
                FallKey(up ? 7 : 6, duration: 0.55),
                FallKey(9, duration: 0.60),
                FallKey(7, duration: 0.55),
            ])
        )
    }
}
