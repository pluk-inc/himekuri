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
    private static let onboardingKey = "himekuri.onboardingTorn"

    private let cal = Calendar.current

    /// The date printed on the page currently on top of the pad.
    @Published private(set) var topDate: Date
    /// Total pages ever torn off.
    @Published private(set) var tornCount: Int
    /// Lesson pages already torn off the front of a fresh pad. They cost no
    /// day, so the calendar underneath is untouched until both are gone.
    @Published private(set) var onboardingTorn: Int
    /// Start of the current real day (refreshed at midnight / on activation).
    /// Deliberately not `@Published`: no view reads it, and `refreshToday()`
    /// runs on every activation — republishing would redraw the whole pad.
    private(set) var today: Date

    init() {
        let defaults = UserDefaults.standard
        let now = Calendar.current.startOfDay(for: Date())
        today = now
        tornCount = defaults.integer(forKey: Self.tornCountKey)
        onboardingTorn = Self.storedOnboardingTorn(defaults)
        if let stored = defaults.object(forKey: Self.topDateKey) as? Double {
            // Never rewind, even if the clock moved backwards.
            topDate = Calendar.current.startOfDay(for: Date(timeIntervalSinceReferenceDate: stored))
        } else {
            topDate = now
        }
    }

    /// How many lesson pages this pad has already lost. Absent the key, the
    /// pad is either new — both lessons still on the front — or belongs to
    /// someone who has been using himekuri since before they existed, which
    /// their own tears and theme choice give away. A pad that has only ever
    /// been looked at gets the lessons; they cost it nothing.
    private static func storedOnboardingTorn(_ defaults: UserDefaults) -> Int {
        let lessons = OnboardingPage.allCases.count
        // `integer(forKey:)` rather than a cast: it reads back whatever the
        // key is actually typed as, including a string set on the command line.
        if defaults.object(forKey: onboardingKey) != nil {
            return min(max(defaults.integer(forKey: onboardingKey), 0), lessons)
        }
        let alreadyUsed = defaults.object(forKey: topDateKey) != nil
            || defaults.object(forKey: tornCountKey) != nil
            || defaults.object(forKey: PageTheme.defaultsKey) != nil
        return alreadyUsed ? lessons : 0
    }

    /// Tear as far ahead as you like — you just can never go back.
    var canTear: Bool { true }

    var topInfo: DayInfo { DayInfo(date: topDate) }

    /// The day printed on the page underneath. While a lesson is on top the
    /// pad hasn't started counting yet, so what's revealed is still today.
    var nextInfo: DayInfo {
        guard onboardingPage == nil else { return topInfo }
        return DayInfo(date: cal.date(byAdding: .day, value: 1, to: topDate) ?? topDate)
    }

    /// The lesson printed on the top page, or nil once the pad prints days.
    var onboardingPage: OnboardingPage? { OnboardingPage.page(after: onboardingTorn) }

    /// The lesson printed on the page underneath, if there's another one.
    var nextOnboardingPage: OnboardingPage? { OnboardingPage.page(after: onboardingTorn + 1) }

    /// Fraction of the current year still on the pad (drives visual thickness).
    var remainingFraction: Double {
        let dayOfYear = cal.ordinality(of: .day, in: .year, for: topDate) ?? 1
        let days = cal.range(of: .day, in: .year, for: topDate)?.count ?? 365
        return 1.0 - Double(dayOfYear - 1) / Double(days)
    }

    /// Irreversible: advances the pad by one page and persists immediately.
    /// A lesson page is the exception — it leaves its stub under the staples
    /// like any other, but the date underneath doesn't move.
    func tear() {
        if onboardingPage != nil {
            onboardingTorn += 1
            tornCount += 1
            persist()
            return
        }
        guard let next = cal.date(byAdding: .day, value: 1, to: topDate) else { return }
        topDate = next
        tornCount += 1
        persist()
    }

    func refreshToday() {
        today = cal.startOfDay(for: Date())
        // Lessons take as long as they take: a pad still on them hasn't spent
        // a day, so the first real page is whatever day it's uncovered on.
        if onboardingPage != nil, topDate != today {
            topDate = today
            persist()
        }
    }

    /// The one deliberate escape hatch, reachable only from dev builds — it
    /// puts the lesson pages back too, so the first run can be tried again.
    func resetToToday() {
        onboardingTorn = 0
        refreshToday()
        topDate = today
        persist()
    }

    private func persist() {
        let defaults = UserDefaults.standard
        defaults.set(topDate.timeIntervalSinceReferenceDate, forKey: Self.topDateKey)
        defaults.set(tornCount, forKey: Self.tornCountKey)
        defaults.set(onboardingTorn, forKey: Self.onboardingKey)
    }
}
