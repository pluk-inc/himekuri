//
//  CalendarStore.swift
//  himekuri
//
//  The pad of pages. Tearing only ever moves forward — there is no way back.
//

import Combine
import Foundation

extension Notification.Name {
    /// Posted by the dev-only menu item to snap the pad back to today's page.
    static let himekuriResetToToday = Notification.Name("himekuri.resetToToday")
}

/// `ObservableObject` rather than `@Observable`: the latter needs macOS 14,
/// and the pad has to work back to Monterey.
final class CalendarStore: ObservableObject {
    private static let topDateKey = "himekuri.topDate"
    private static let tornCountKey = "himekuri.tornCount"

    private let cal = Calendar.current

    /// The date printed on the page currently on top of the pad.
    @Published private(set) var topDate: Date
    /// Total pages ever torn off.
    @Published private(set) var tornCount: Int
    /// Start of the current real day (refreshed at midnight / on activation).
    /// Deliberately not `@Published`: no view reads it, and `refreshToday()`
    /// runs on every activation — republishing would redraw the whole pad.
    private(set) var today: Date

    init() {
        let defaults = UserDefaults.standard
        let now = Calendar.current.startOfDay(for: Date())
        today = now
        tornCount = defaults.integer(forKey: Self.tornCountKey)
        if let stored = defaults.object(forKey: Self.topDateKey) as? Double {
            // Never rewind, even if the clock moved backwards.
            topDate = Calendar.current.startOfDay(for: Date(timeIntervalSinceReferenceDate: stored))
        } else {
            topDate = now
        }
    }

    /// Tear as far ahead as you like — you just can never go back.
    var canTear: Bool { true }

    var topInfo: DayInfo { DayInfo(date: topDate) }

    var nextInfo: DayInfo {
        DayInfo(date: cal.date(byAdding: .day, value: 1, to: topDate) ?? topDate)
    }

    /// Fraction of the current year still on the pad (drives visual thickness).
    var remainingFraction: Double {
        let dayOfYear = cal.ordinality(of: .day, in: .year, for: topDate) ?? 1
        let days = cal.range(of: .day, in: .year, for: topDate)?.count ?? 365
        return 1.0 - Double(dayOfYear - 1) / Double(days)
    }

    /// Irreversible: advances the pad by one page and persists immediately.
    func tear() {
        guard let next = cal.date(byAdding: .day, value: 1, to: topDate) else { return }
        topDate = next
        tornCount += 1
        persist()
    }

    func refreshToday() {
        today = cal.startOfDay(for: Date())
    }

    /// The one deliberate escape hatch, reachable only from dev builds.
    func resetToToday() {
        refreshToday()
        topDate = today
        persist()
    }

    private func persist() {
        let defaults = UserDefaults.standard
        defaults.set(topDate.timeIntervalSinceReferenceDate, forKey: Self.topDateKey)
        defaults.set(tornCount, forKey: Self.tornCountKey)
    }
}
