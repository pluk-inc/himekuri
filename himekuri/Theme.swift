//
//  Theme.swift
//  himekuri
//
//  Shared layout metrics, print palette, and typography.
//

import SwiftUI

nonisolated enum Metrics {
    static let pageW: CGFloat = 300
    static let pageH: CGFloat = 400
    static let bindingH: CGFloat = 26
    /// How far the page top sits below the binding's top edge (block-local).
    static let pageTopInset: CGFloat = 6
    /// Page-local y of the tear line (the paper above this stays under the staples).
    static let tearY: CGFloat = 20
    static let blockTopPad: CGFloat = 26
    static let windowW: CGFloat = 480
    static let windowH: CGFloat = 690
    /// Pull needed to *initiate* the tear. Once the crack is running, stress
    /// focuses at its tip and each next fiber needs less (see tearGesture).
    static let tearThreshold: CGFloat = 118
    /// Fraction of the page (from the bottom) that responds to the tear gesture —
    /// everything below the binding; only the binding itself moves the window.
    static let tearZone: CGFloat = 0.93
    /// Transparent margin baked around the top page so the distortion shader can sample it.
    static let shaderPadX: CGFloat = 70
    static let shaderPadBottom: CGFloat = 210
}

enum Ink {
    static let paper = Color(red: 0.965, green: 0.945, blue: 0.895)
    static let paperEdge = Color(red: 0.88, green: 0.845, blue: 0.77)
    static let black = Color(red: 0.10, green: 0.09, blue: 0.10)
    static let vermilion = Color(red: 0.82, green: 0.22, blue: 0.13)
    static let indigo = Color(red: 0.18, green: 0.29, blue: 0.55)
    static let grain = Color(red: 0.45, green: 0.38, blue: 0.28)
}

enum Theme {
    /// Heavy gothic for kanji (Hiragino Sans falls back to system if missing).
    static func kanji(_ size: CGFloat) -> Font {
        .custom("HiraginoSans-W7", size: size)
    }

    /// Mincho (serif) for smaller traditional text.
    static func mincho(_ size: CGFloat) -> Font {
        .custom("HiraMinProN-W6", size: size)
    }

    /// Fat slab numeral for the big day number.
    static func numeral(_ size: CGFloat) -> Font {
        .system(size: size, weight: .black, design: .serif)
    }
}

/// Deterministic xorshift RNG so tear edges / stubs reproduce across launches.
nonisolated struct SeededRandom {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed == 0 ? 0x9E3779B97F4A7C15 : seed
    }

    mutating func next() -> UInt64 {
        state ^= state << 13
        state ^= state >> 7
        state ^= state << 17
        return state
    }

    /// Uniform in [0, 1).
    mutating func unit() -> Float {
        Float(next() % 1_000_000) / 1_000_000
    }

    mutating func range(_ r: ClosedRange<Float>) -> Float {
        r.lowerBound + unit() * (r.upperBound - r.lowerBound)
    }

    mutating func cg(_ r: ClosedRange<CGFloat>) -> CGFloat {
        r.lowerBound + CGFloat(unit()) * (r.upperBound - r.lowerBound)
    }
}

/// Seed for the n-th tear (0-based), stable across launches.
nonisolated func tearSeed(for tornCount: Int) -> UInt64 {
    (UInt64(tornCount) &+ 1) &* 0x9E3779B97F4A7C15
}
