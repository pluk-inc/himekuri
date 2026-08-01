//
//  SeededRandom.swift
//  himekuri
//
//  Deterministic xorshift RNG so tear edges / stubs reproduce across launches.
//

import Foundation

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
