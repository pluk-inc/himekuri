//
//  CalendarStore.swift
//  himekuri
//
//  The pad of pages. Tearing only ever moves forward — there is no way back.
//

import Foundation
import Observation

extension Notification.Name {
    /// Posted by the menu bar to snap the pad back to today's page.
    static let himekuriResetToToday = Notification.Name("himekuri.resetToToday")
}

@Observable
final class CalendarStore {
    private static let topDateKey = "himekuri.topDate"
    private static let tornCountKey = "himekuri.tornCount"

    private let cal = Calendar.current

    /// The date printed on the page currently on top of the pad.
    private(set) var topDate: Date
    /// Total pages ever torn off.
    private(set) var tornCount: Int
    /// Start of the current real day (refreshed at midnight / on activation).
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

    /// The one deliberate escape hatch: snap the pad back (or forward) to today.
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

// MARK: - Day info

nonisolated struct DayInfo: Equatable {
    let date: Date
    let year: Int
    let month: Int
    let day: Int
    /// 1 = Sunday … 7 = Saturday
    let weekday: Int
    let dayOfYear: Int
    let weekOfYear: Int
    let rokuyo: String
    /// Lunisolar (旧暦) month and day.
    let lunarMonth: Int
    let lunarDay: Int
    /// Weeks of the month, Sunday-first, nil for blanks.
    let grid: [[Int?]]

    init(date: Date) {
        let cal = Calendar(identifier: .gregorian)
        self.date = date
        let c = cal.dateComponents([.year, .month, .day, .weekday], from: date)
        year = c.year ?? 2026
        month = c.month ?? 1
        day = c.day ?? 1
        weekday = c.weekday ?? 1
        dayOfYear = cal.ordinality(of: .day, in: .year, for: date) ?? 1
        weekOfYear = cal.component(.weekOfYear, from: date)

        // Rokuyō from the lunisolar calendar: (lunar month + lunar day) mod 6.
        let chinese = Calendar(identifier: .chinese)
        let lm = chinese.component(.month, from: date)
        let ld = chinese.component(.day, from: date)
        lunarMonth = lm
        lunarDay = ld
        rokuyo = ["大安", "赤口", "先勝", "友引", "先負", "仏滅"][(lm + ld) % 6]

        // Mini month grid.
        var weeks: [[Int?]] = []
        if let dayRange = cal.range(of: .day, in: .month, for: date),
           let first = cal.date(from: DateComponents(year: year, month: month, day: 1)) {
            let lead = cal.component(.weekday, from: first) - 1
            var week: [Int?] = Array(repeating: nil, count: lead)
            for d in dayRange {
                week.append(d)
                if week.count == 7 {
                    weeks.append(week)
                    week = []
                }
            }
            if !week.isEmpty {
                week.append(contentsOf: Array(repeating: nil, count: 7 - week.count))
                weeks.append(week)
            }
        }
        grid = weeks
    }

    var weekdayKanji: String {
        ["日曜日", "月曜日", "火曜日", "水曜日", "木曜日", "金曜日", "土曜日"][weekday - 1]
    }

    var weekdayEN: String {
        ["SUN", "MON", "TUE", "WED", "THU", "FRI", "SAT"][weekday - 1]
    }

    var isSunday: Bool { weekday == 1 }
    var isSaturday: Bool { weekday == 7 }

    var reiwa: String {
        year >= 2019 ? "令和\(year - 2018)年" : "平成\(year - 1988)年"
    }

    var proverb: (jp: String, en: String) {
        Proverbs.all[dayOfYear % Proverbs.all.count]
    }
}

// MARK: - Daily proverbs

nonisolated enum Proverbs {
    static let all: [(jp: String, en: String)] = [
        ("七転び八起き", "Fall seven times, rise eight."),
        ("塵も積もれば山となる", "Even dust, piled up, becomes a mountain."),
        ("継続は力なり", "Persistence is power."),
        ("明日は明日の風が吹く", "Tomorrow, tomorrow's wind will blow."),
        ("石の上にも三年", "Three years sitting on a stone."),
        ("花より団子", "Dumplings over flowers."),
        ("一期一会", "One time, one meeting."),
        ("猿も木から落ちる", "Even monkeys fall from trees."),
        ("急がば回れ", "When in a hurry, take the long way round."),
        ("初心忘るべからず", "Never forget the beginner's spirit."),
        ("案ずるより産むが易し", "Doing is easier than fearing."),
        ("笑う門には福来る", "Fortune visits a laughing gate."),
        ("千里の道も一歩から", "A thousand-mile road starts with one step."),
        ("温故知新", "Study the old to know the new."),
        ("雨降って地固まる", "After the rain, the earth hardens."),
        ("井の中の蛙大海を知らず", "A frog in a well knows not the ocean."),
    ]
}
