//
//  Metrics.swift
//  himekuri
//
//  Shared layout metrics for the pad and its window.
//

import Foundation

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
    /// focuses at its tip and each next fiber needs less (see ContentView).
    static let tearThreshold: CGFloat = 118
    /// Fraction of the page (from the bottom) that responds to the tear gesture —
    /// everything below the binding; only the binding itself moves the window.
    static let tearZone: CGFloat = 0.93
    /// Transparent margin around the top page so the simulated sheet can
    /// swing and droop past the page bounds without clipping.
    static let overhangX: CGFloat = 70
    static let overhangBottom: CGFloat = 210
}
