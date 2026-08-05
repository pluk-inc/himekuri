//
//  FallingPage.swift
//  himekuri
//
//  Everything the freed piece needs to fall on its own.
//

import Foundation

struct FallingPage: Identifiable {
    let id = UUID()
    let info: DayInfo
    let theme: PageTheme
    /// Set when the freed piece is one of the pad's lesson pages.
    var onboarding: OnboardingPage? = nil
    let seed: UInt64
    let start: CGSize
    let grabX: CGFloat
    /// Torn by an upward flick: the piece is flung over the staples first.
    let upward: Bool
    /// Hand speed at the moment the fibers gave — the throw it inherits.
    let throwVelocity: CGSize
}
