//
//  DayInfo.swift
//  himekuri
//
//  Everything a printed page needs to know about one day.
//

import Foundation

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
    /// Lunisolar (旧暦 / 农历) month and day.
    let lunarMonth: Int
    let lunarDay: Int
    /// A leap (閏/闰) lunar month repeats its number.
    let isLeapLunarMonth: Bool
    /// Position of the lunar year in the 60-year sexagenary cycle (1–60).
    let cycleYear: Int
    /// Era-aware Japanese year (令和8年), from the system's Japanese calendar.
    let eraYear: String
    /// Weeks of the month, Sunday-first, nil for blanks.
    let grid: [[Int?]]
    /// The lunisolar calendar for this day: months, leap months, moon, terms.
    let lunisolar: Lunisolar
    /// The almanac's reading of the day, laid over that calendar.
    let almanac: Almanac

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

        // The lunisolar calendar underneath every traditional page, and the
        // almanac reading that sits on top of it.
        let ls = Lunisolar(year: year, month: month, day: day, date: date)
        lunisolar = ls
        almanac = Almanac(year: year, month: month, day: day, lunarMonth: ls.month)

        lunarMonth = ls.month
        lunarDay = ls.day
        isLeapLunarMonth = ls.isLeapMonth
        cycleYear = ls.cycleYear
        // Rokuyō from the lunisolar date: (lunar month + lunar day) mod 6.
        rokuyo = ["大安", "赤口", "先勝", "友引", "先負", "仏滅"][(ls.month + ls.day) % 6]

        // The era from the real Japanese calendar, so a future era change
        // doesn't need an app update.
        let eraFormatter = DateFormatter()
        eraFormatter.calendar = Calendar(identifier: .japanese)
        eraFormatter.locale = Locale(identifier: "ja_JP")
        eraFormatter.dateFormat = "GGGGy年"
        eraYear = eraFormatter.string(from: date)

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

    var reiwa: String { eraYear }

    var proverb: (jp: String, en: String) {
        Proverbs.all[dayOfYear % Proverbs.all.count]
    }
}
