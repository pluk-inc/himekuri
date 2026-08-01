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
