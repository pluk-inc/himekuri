//
//  Lunisolar.swift
//  himekuri
//
//  The calendar layer: 農曆 proper. Lunar months and their length, leap
//  months, the moon's phase, the 24 solar terms, and the festivals that hang
//  off both. Nothing here passes judgement on the day — that's the almanac's
//  job, and it lives in Almanac.swift on top of this.
//
//  "Lunar calendar" is loose talk: months come from the moon, the solar terms
//  come from the sun, and the leap month is what reconciles them. Lunisolar.
//

import Foundation

nonisolated struct Lunisolar: Equatable {
    /// Lunar month, 1–12. A leap month repeats the number it follows.
    let month: Int
    /// Lunar day, 1–30.
    let day: Int
    let isLeapMonth: Bool
    /// Position of the lunar year in the 60-year sexagenary cycle, 1–60.
    let cycleYear: Int
    /// A 大 month runs 30 days, a 小 month 29. The moon does not do round numbers.
    let monthIsLong: Bool
    /// The solar term that begins on this day (節氣), if one does.
    let solarTerm: String?
    /// The festival falling on this day, lunar or solar-term derived.
    let festival: String?
    /// Lit fraction of the moon's disc, 0…1.
    let illumination: Double
    let isWaxing: Bool

    init(year: Int, month gregorianMonth: Int, day gregorianDay: Int, date: Date) {
        let chinese = Calendar(identifier: .chinese)
        let c = chinese.dateComponents([.year, .month, .day], from: date)
        let m = c.month ?? 1
        let d = c.day ?? 1
        month = m
        day = d
        isLeapMonth = c.isLeapMonth ?? false
        cycleYear = c.year ?? 1

        // Month length: step to what would be the 30th and see if it exists.
        let gregorian = Calendar(identifier: .gregorian)
        if let monthStart = gregorian.date(byAdding: .day, value: -(d - 1), to: date),
           let twentyNinth = gregorian.date(byAdding: .day, value: 29, to: monthStart) {
            monthIsLong = (chinese.dateComponents([.day], from: twentyNinth).day ?? 1) == 30
        } else {
            monthIsLong = true
        }

        let term = Self.solarTerm(year: year, month: gregorianMonth, day: gregorianDay)
        solarTerm = term
        festival = Self.festival(lunarMonth: m, lunarDay: d, isLeapMonth: c.isLeapMonth ?? false,
                                solarTerm: term, date: date)

        illumination = Astro.moonIllumination(date)
        isWaxing = Astro.moonIsWaxing(date)
    }

    // MARK: - Solar terms

    /// The 24 terms, indexed by which 15° arc of the ecliptic the sun has just
    /// entered — index 0 is the vernal equinox at 0°.
    static let termNames = [
        "春分", "清明", "穀雨", "立夏", "小滿", "芒種",
        "夏至", "小暑", "大暑", "立秋", "處暑", "白露",
        "秋分", "寒露", "霜降", "立冬", "小雪", "大雪",
        "冬至", "小寒", "大寒", "立春", "雨水", "驚蟄",
    ]

    /// A term belongs to the UTC+8 civil day it falls in — the same reckoning
    /// ICU's chinese calendar uses for month boundaries, so the two agree.
    private static func solarTerm(year: Int, month: Int, day: Int) -> String? {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = Astro.chinaTimeZone
        guard let start = cal.date(from: DateComponents(year: year, month: month, day: day)) else {
            return nil
        }
        let end = start.addingTimeInterval(86400)
        let before = Int(Astro.sunLongitude(start) / 15)
        let after = Int(Astro.sunLongitude(end) / 15)
        guard before != after else { return nil }
        return termNames[after % 24]
    }

    // MARK: - Festivals

    private static func festival(lunarMonth m: Int, lunarDay d: Int, isLeapMonth: Bool,
                                 solarTerm: String?, date: Date) -> String? {
        // 清明 is both a term and a festival; the rest of the terms are not.
        if solarTerm == "清明" { return "清明節" }

        // A leap month repeats a number but never its festivals.
        guard !isLeapMonth else { return nil }

        switch (m, d) {
        case (1, 1): return "春節"
        case (1, 15): return "元宵節"
        case (2, 2): return "龍抬頭"
        case (3, 3): return "上巳節"
        case (5, 5): return "端午節"
        case (7, 7): return "七夕"
        case (7, 15): return "中元節"
        case (8, 15): return "中秋節"
        case (9, 9): return "重陽節"
        case (10, 15): return "下元節"
        case (12, 8): return "臘八節"
        case (12, 23): return "送灶"
        default: break
        }

        // 除夕 is the last day of the last lunar month, whether that's the
        // 29th or the 30th — so ask whether tomorrow is New Year's Day.
        if m == 12, d >= 29 {
            let chinese = Calendar(identifier: .chinese)
            if let tomorrow = Calendar(identifier: .gregorian).date(byAdding: .day, value: 1, to: date) {
                let next = chinese.dateComponents([.month, .day], from: tomorrow)
                if next.month == 1, next.day == 1 { return "除夕" }
            }
        }
        return nil
    }

    // MARK: - Names (traditional forms, as a 通勝 prints them)

    /// 正月, 二月 … 十一月, 十二月, with 閏 for a leap month — the plain forms
    /// both almanac pages print, rather than the literary 冬月 / 臘月.
    var monthName: String {
        let names = ["", "正月", "二月", "三月", "四月", "五月", "六月",
                     "七月", "八月", "九月", "十月", "十一月", "十二月"]
        guard month >= 1, month <= 12 else { return "" }
        return (isLeapMonth ? "閏" : "") + names[month]
    }

    /// 初一, 十五, 廿三, 三十 — the almanac's own numerals.
    var dayName: String {
        let ones = ["", "一", "二", "三", "四", "五", "六", "七", "八", "九", "十"]
        switch day {
        case 1...10: return "初" + ones[day]
        case 11...19: return "十" + ones[day - 10]
        case 20: return "二十"
        case 21...29: return "廿" + ones[day - 20]
        default: return "三十"
        }
    }

    /// 大 for a 30-day month, 小 for a 29-day one.
    var monthLengthMark: String { monthIsLong ? "大" : "小" }

    var yearGanzhi: String {
        Ganzhi.stems[(cycleYear - 1) % 10] + Ganzhi.branches[(cycleYear - 1) % 12]
    }

    /// 生肖 of the lunar year, in traditional forms.
    var zodiac: String {
        Ganzhi.zodiacs[(cycleYear - 1) % 12]
    }

    /// 朔 / 上弦 / 望 / 下弦 — marked only on the day it lands on, the way a
    /// printed almanac does. The month is defined by the new moon, so these
    /// come from the lunar day rather than from a second, disagreeing sum.
    var moonPhaseName: String? {
        switch day {
        case 1: return "朔"
        case 8: return "上弦"
        case 15: return "望"
        case 23: return "下弦"
        default: return nil
        }
    }
}

/// Stems, branches, and the animals — shared by the calendar and the almanac.
nonisolated enum Ganzhi {
    static let stems = ["甲", "乙", "丙", "丁", "戊", "己", "庚", "辛", "壬", "癸"]
    static let branches = ["子", "丑", "寅", "卯", "辰", "巳", "午", "未", "申", "酉", "戌", "亥"]
    static let zodiacs = ["鼠", "牛", "虎", "兔", "龍", "蛇", "馬", "羊", "猴", "雞", "狗", "豬"]
    /// The twelve double-hours, 子時 starting at 23:00.
    static let hourNames = ["子", "丑", "寅", "卯", "辰", "巳", "午", "未", "申", "酉", "戌", "亥"]
}
