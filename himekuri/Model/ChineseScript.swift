//
//  ChineseScript.swift
//  himekuri
//
//  The two almanac pages print the same system under two names, and the names
//  carry a script with them: 通勝 is the Cantonese book, set in traditional
//  characters for Hong Kong and Southeast Asia; 黄历 is the Mandarin one, set
//  in simplified for the mainland. The model speaks traditional throughout and
//  the Huangli page asks for its own register here.
//

import Foundation

nonisolated enum ChineseScript {
    case traditional
    case simplified

    /// Converts a string the almanac model produced.
    ///
    /// This is deliberately **not** a general-purpose converter — it maps only
    /// the characters that appear in this app's own closed vocabulary (the
    /// twelve officers, the 28 mansions, the zodiac, the 宜/忌 verbs, the
    /// solar terms, the festivals, and the direction words). Anything outside
    /// that set passes through untouched, which is correct here and would be
    /// wrong anywhere else.
    func render(_ text: String) -> String {
        guard self == .simplified else { return text }
        return String(text.map { Self.simplifications[$0] ?? $0 })
    }

    private static let simplifications: [Character: Character] = [
        // 建除十二神
        "滿": "满", "執": "执", "開": "开", "閉": "闭",
        // 二十八宿
        "虛": "虚", "婁": "娄", "畢": "毕", "參": "参", "張": "张", "軫": "轸",
        // 生肖
        "龍": "龙", "雞": "鸡", "豬": "猪", "馬": "马",
        // 宜 / 忌
        "動": "动", "倉": "仓", "療": "疗", "掃": "扫", "財": "财", "納": "纳",
        "藥": "药", "種": "种", "詞": "词", "訟": "讼", "牆": "墙", "帶": "带",
        "訴": "诉", "遠": "远", "壞": "坏", "醫": "医", "撫": "抚", "學": "学",
        "進": "进", "築": "筑",
        // 納音
        "劍": "剑", "鋒": "锋", "驛": "驿", "楊": "杨", "澗": "涧", "爐": "炉",
        "蠟": "蜡", "燈": "灯", "釵": "钗", "釧": "钏", "長": "长", "靂": "雳",
        // 節氣
        "穀": "谷", "處": "处", "驚": "惊", "蟄": "蛰",
        // 節日
        "節": "节", "陽": "阳", "臘": "腊", "頭": "头",
        // calendar words and directions
        "閏": "闰", "農": "农", "曆": "历", "東": "东", "沖": "冲", "時": "时",
        "發": "发", "歲": "岁",
    ]
}
