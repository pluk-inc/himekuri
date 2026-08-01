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
        let lunar = chinese.dateComponents([.year, .month, .day], from: date)
        let lm = lunar.month ?? 1
        let ld = lunar.day ?? 1
        lunarMonth = lm
        lunarDay = ld
        isLeapLunarMonth = lunar.isLeapMonth ?? false
        cycleYear = lunar.year ?? 1
        rokuyo = ["大安", "赤口", "先勝", "友引", "先負", "仏滅"][(lm + ld) % 6]

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

    /// 干支 — the sexagenary year name (丙午年).
    var ganzhiYear: String {
        let stems = ["甲", "乙", "丙", "丁", "戊", "己", "庚", "辛", "壬", "癸"]
        let branches = ["子", "丑", "寅", "卯", "辰", "巳", "午", "未", "申", "酉", "戌", "亥"]
        return stems[(cycleYear - 1) % 10] + branches[(cycleYear - 1) % 12] + "年"
    }

    /// 生肖 — the zodiac animal of the lunar year.
    var zodiac: String {
        ["鼠", "牛", "虎", "兔", "龙", "蛇", "马", "羊", "猴", "鸡", "狗", "猪"][(cycleYear - 1) % 12]
    }

    /// The lunar month in Chinese almanac convention (正月…冬月, 腊月, 闰X月).
    var lunarMonthCN: String {
        let names = ["", "正月", "二月", "三月", "四月", "五月", "六月",
                     "七月", "八月", "九月", "十月", "冬月", "腊月"]
        return (isLeapLunarMonth ? "闰" : "") + names[lunarMonth]
    }

    /// The lunar day in Chinese almanac convention (初八, 十五, 廿三, 三十).
    var lunarDayCN: String {
        let ones = ["", "一", "二", "三", "四", "五", "六", "七", "八", "九", "十"]
        switch lunarDay {
        case 1...10: return "初" + ones[lunarDay]
        case 11...19: return "十" + ones[lunarDay - 10]
        case 20: return "二十"
        case 21...29: return "廿" + ones[lunarDay - 20]
        default: return "三十"
        }
    }

    var proverb: (jp: String, en: String) {
        Proverbs.all[dayOfYear % Proverbs.all.count]
    }
}
