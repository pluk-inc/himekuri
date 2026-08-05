//
//  OnboardingPage.swift
//  himekuri
//
//  The two pages a fresh pad opens with. They print a lesson instead of a
//  date — the gesture, then where the other prints live — and tearing one
//  costs no day: today's page is still waiting underneath.
//

import Foundation

nonisolated enum OnboardingPage: Int, CaseIterable {
    /// The gesture itself: pull until the fibers give.
    case pull = 0
    /// Where the other prints are: the menu bar, up above the pad.
    case prints = 1

    /// The small line above the rule.
    var kicker: String {
        switch self {
        case .pull: String(localized: "WELCOME")
        case .prints: String(localized: "PRINT STYLES")
        }
    }

    var headline: String {
        switch self {
        case .pull: String(localized: "Pull the page down")
        case .prints: String(localized: "Seven prints")
        }
    }

    var note: String {
        switch self {
        case .pull: String(localized: "Grab the sheet anywhere and pull down until the paper gives.")
        case .prints: String(localized: "Click the calendar in the menu bar, then Theme, to print the pad another way.")
        }
    }

    /// The label on the diagram.
    var cue: String {
        switch self {
        case .pull: String(localized: "PULL")
        case .prints: String(localized: "UP HERE")
        }
    }

    /// The way on from this page. The last lesson has to say outright that
    /// tearing it is what brings the calendar up — nobody should have to
    /// guess that the pad is still waiting behind it.
    var closer: String? {
        switch self {
        case .pull: nil
        case .prints: String(localized: "Pull this page down for today's date")
        }
    }

    var footer: String { String(localized: "Practice page · costs no day") }

    /// "1 / 2" — how far into the two free tears this page is.
    var step: String { "\(rawValue + 1) / \(OnboardingPage.allCases.count)" }

    /// The lesson on top of a pad that has had `torn` lesson pages taken off,
    /// or nil once both are gone and the pad prints real days.
    static func page(after torn: Int) -> OnboardingPage? {
        OnboardingPage(rawValue: torn)
    }
}
