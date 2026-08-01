//
//  Haptics.swift
//  himekuri
//
//  Trackpad haptics for the tear.
//

import AppKit

enum Haptics {
    /// Small tick while the paper stretches.
    static func tick() {
        NSHapticFeedbackManager.defaultPerformer.perform(.alignment, performanceTime: .now)
    }

    /// The moment the page lets go.
    static func rip() {
        NSHapticFeedbackManager.defaultPerformer.perform(.levelChange, performanceTime: .now)
    }
}
