//
//  Almanac.swift
//  himekuri
//
//  The almanac layer. Everything here is *judgement* laid over the
//  lunisolar date — the day's stem and branch, its element, its mansion, which
//  of the twelve officers holds it, what that makes the day fit and unfit for,
//  who it clashes with, and which hours are open.
//
//  Both almanac pages read this: 通勝 and 黄历 are the same system under a
//  Cantonese and a Mandarin name, so the type carries neither. The rules are
//  the ones both print, and they are rules, not physics: the
//  day pillar is a 60-count from a fixed epoch, the officer is the distance
//  from the month's own branch, the lucky hours are the black-and-yellow
//  road spirits walking their circuit. All of it is arithmetic on a date.
//

import Foundation

nonisolated struct Almanac: Equatable {
    /// 0 = 甲 … 9 = 癸
    let dayStem: Int
    /// 0 = 子 … 11 = 亥
    let dayBranch: Int
    /// Position in the 60-cycle, 0 = 甲子.
    let daySexagenary: Int
    /// Which of the twelve officers holds the day (建除十二神), 0 = 建.
    let officer: Int
    /// Which of the 28 mansions is on duty, 0 = 角.
    let mansion: Int

    init(year: Int, month: Int, day: Int, lunarMonth: Int) {
        let jdn = Self.julianDayNumber(year: year, month: month, day: day)

        // 1 January 2024 + 1 day was 乙丑, sexagenary index 1. The count has
        // not been interrupted since, so one anchor fixes every other day.
        let sexagenary = Self.mod(1 + (jdn - Self.ganzhiEpoch), 60)
        daySexagenary = sexagenary
        dayStem = sexagenary % 10
        dayBranch = sexagenary % 12

        // 建 falls on the day whose branch matches the lunar month's own
        // branch — 正月 is the month of 寅, so 十一月 is the month of 子.
        let monthBranch = (lunarMonth + 1) % 12
        officer = Self.mod(dayBranch - monthBranch, 12)

        // 1 January 2027 was 鬼宿, index 22 — the 28-day round never stops either.
        mansion = Self.mod(22 + (jdn - Self.mansionEpoch), 28)
    }

    // MARK: - Epochs

    /// JDN of 2 January 2024 (乙丑日).
    private static let ganzhiEpoch = julianDayNumber(year: 2024, month: 1, day: 2)
    /// JDN of 1 January 2027 (鬼宿).
    private static let mansionEpoch = julianDayNumber(year: 2027, month: 1, day: 1)

    /// Julian Day Number straight from the printed date — no timezone in it,
    /// so day counts never drift by one for a reader outside UTC+8.
    static func julianDayNumber(year: Int, month: Int, day: Int) -> Int {
        let a = (month - 14) / 12
        return (1461 * (year + 4800 + a)) / 4
            + (367 * (month - 2 - 12 * a)) / 12
            - (3 * ((year + 4900 + a) / 100)) / 4
            + day - 32075
    }

    private static func mod(_ a: Int, _ n: Int) -> Int {
        let r = a % n
        return r < 0 ? r + n : r
    }

    // MARK: - The day pillar

    /// 庚辰 — the day's stem and branch.
    var dayGanzhi: String {
        Ganzhi.stems[dayStem] + Ganzhi.branches[dayBranch]
    }

    /// 白蠟金 — the day's 納音, the element sound of its stem-branch pair.
    var nayin: String {
        Self.nayins[daySexagenary / 2]
    }

    /// 金 — just the element, which is what the page has room for.
    var element: String {
        String(nayin.suffix(1))
    }

    private static let nayins = [
        "海中金", "爐中火", "大林木", "路旁土", "劍鋒金", "山頭火",
        "澗下水", "城頭土", "白蠟金", "楊柳木", "泉中水", "屋上土",
        "霹靂火", "松柏木", "長流水", "沙中金", "山下火", "平地木",
        "壁上土", "金箔金", "覆燈火", "天河水", "大驛土", "釵釧金",
        "桑柘木", "大溪水", "沙中土", "天上火", "石榴木", "大海水",
    ]

    // MARK: - The officer, and what it permits

    /// 建, 除, 滿 … 閉
    var officerName: String {
        ["建", "除", "滿", "平", "定", "執", "破", "危", "成", "收", "開", "閉"][officer]
    }

    /// 定日 — how the almanac names the day itself.
    var officerDay: String { officerName + "日" }

    /// 宜 — what the day is fit for.
    var good: [String] { Self.officerAdvice[officer].good }

    /// 忌 — what it is not.
    var bad: [String] { Self.officerAdvice[officer].bad }

    /// The twelve officers' standing advice, in the order 建 … 閉.
    private static let officerAdvice: [(good: [String], bad: [String])] = [
        (["祭祀", "祈福", "出行", "上任"], ["動土", "開倉", "掘井", "安葬"]),
        (["除服", "療病", "掃舍", "解除"], ["出行", "赴任", "求財", "嫁娶"]),
        (["祭祀", "祈福", "開市", "納財"], ["服藥", "栽種", "詞訟", "安葬"]),
        (["修牆", "平路", "掃舍", "納畜"], ["開渠", "掘井", "栽種", "嫁娶"]),
        (["祭祀", "冠帶", "嫁娶", "安床"], ["出行", "訴訟", "移徙", "開倉"]),
        (["捕捉", "祭祀", "造屋", "納畜"], ["開市", "出財", "遠行", "移徙"]),
        (["破屋", "壞垣", "求醫", "解除"], ["嫁娶", "開市", "動土", "出行"]),
        (["祭祀", "安撫", "解除", "掃舍"], ["登高", "行船", "出行", "動土"]),
        (["嫁娶", "開市", "立券", "入學"], ["訴訟", "破土", "求醫", "移徙"]),
        (["納財", "進人口", "捕捉", "納畜"], ["開市", "安葬", "出行", "求醫"]),
        (["祭祀", "開市", "入學", "動土"], ["安葬", "破土", "詞訟", "赴任"]),
        (["築堤", "塞穴", "安葬", "納畜"], ["開市", "出行", "求醫", "嫁娶"]),
    ]

    // MARK: - The mansion

    /// 鬼 — the mansion on duty.
    var mansionName: String {
        Self.mansionNames[mansion]
    }

    var mansionFull: String { mansionName + "宿" }

    private static let mansionNames = [
        "角", "亢", "氐", "房", "心", "尾", "箕",
        "斗", "牛", "女", "虛", "危", "室", "壁",
        "奎", "婁", "胃", "昴", "畢", "觜", "參",
        "井", "鬼", "柳", "星", "張", "翼", "軫",
    ]

    // MARK: - Clashes and directions

    /// The branch the day stands opposite to — six along the circle.
    var clashBranch: Int { (dayBranch + 6) % 12 }

    /// 沖狗 — the animal whose year this day runs against.
    var clashAnimal: String { Ganzhi.zodiacs[clashBranch] }

    /// 煞南 — the direction the day's three killings point.
    var evilDirection: String {
        switch dayBranch {
        case 8, 0, 4: return "南"   // 申子辰
        case 5, 9, 1: return "東"   // 巳酉丑
        case 2, 6, 10: return "北"  // 寅午戌
        default: return "西"        // 亥卯未
        }
    }

    /// 財神方位 — where the wealth god stands today, by the day's stem.
    var wealthDirection: String {
        ["東北", "東北", "西南", "西南", "正北", "正北", "正東", "正東", "正南", "正南"][dayStem]
    }

    /// 喜神方位 — where the joy god stands, by the day's stem.
    var joyDirection: String {
        ["東北", "西北", "西南", "正南", "東南", "東北", "西北", "西南", "正南", "東南"][dayStem]
    }

    // MARK: - Hours

    /// The twelve road spirits, six on the yellow road (吉) and six on the
    /// black (凶), walking in this order from wherever the day starts them.
    private static let hourSpirits = [
        ("青龍", true), ("明堂", true), ("天刑", false), ("朱雀", false),
        ("金匱", true), ("天德", true), ("白虎", false), ("玉堂", true),
        ("天牢", false), ("玄武", false), ("司命", true), ("勾陳", false),
    ]

    /// Which hour 青龍 opens on: 申 for a 子 or 午 day, then two branches
    /// later for each pair after it.
    private var firstSpiritBranch: Int { (8 + 2 * (dayBranch % 6)) % 12 }

    /// True when that double-hour falls on the yellow road.
    func hourIsAuspicious(branch: Int) -> Bool {
        Self.hourSpirits[Self.mod(branch - firstSpiritBranch, 12)].1
    }
}
