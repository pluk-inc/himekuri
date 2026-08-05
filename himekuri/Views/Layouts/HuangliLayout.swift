//
//  HuangliLayout.swift
//  himekuri
//
//  黄历 — the Mandarin name for the same almanac the 通勝 page prints, and so
//  set in its own register: simplified characters throughout, and none of the
//  Hijri dating the Southeast Asian pads carry. Green on white inside a double
//  rule, the weekday standing in a filled column, and the 八卦 wheel stamped in
//  the middle of the day's judgements.
//

import SwiftUI

struct HuangliLayout: View {
    let info: DayInfo
    let t: PageTheme

    private var ls: Lunisolar { info.lunisolar }
    private var am: Almanac { info.almanac }

    /// 黄历 is the mainland name, so the page is set in mainland characters.
    private func cn(_ text: String) -> String { ChineseScript.simplified.render(text) }

    var body: some View {
        ZStack {
            // The double rule an almanac page is boxed in.
            Rectangle()
                .strokeBorder(t.ink.opacity(0.9), lineWidth: 2.2)
                .padding(7)
            Rectangle()
                .strokeBorder(t.ink.opacity(0.9), lineWidth: 0.7)
                .padding(11.5)

            VStack(spacing: 0) {
                Spacer().frame(height: 26)
                masthead
                hero
                lunarLine
                adviceBlock
                pillarRow
                Spacer(minLength: 0)
                footer
                Spacer().frame(height: 16)
            }
            .padding(.horizontal, 20)
        }
    }

    // MARK: - Masthead

    private var masthead: some View {
        VStack(spacing: 2) {
            Text(verbatim: "公历 \(info.year)年\(info.month)月 · \(monthNamesEN[info.month])")
                .font(.system(size: 7.5, weight: .semibold, design: .serif))
                .tracking(0.5)
                .foregroundStyle(t.ink.opacity(0.85))
            HStack(spacing: 7) {
                Text(verbatim: cn(ls.yearGanzhi) + "年")
                    .font(Theme.mincho(14))
                Text(verbatim: "【\(cn(ls.zodiac))】")
                    .font(Theme.mincho(12))
            }
            .foregroundStyle(t.ink)
            Rectangle()
                .fill(t.ink.opacity(0.7))
                .frame(height: 0.7)
                .padding(.top, 4)
        }
    }

    // MARK: - Hero

    /// Numeral in the middle, the good-luck couplet down one side and the
    /// weekday standing in a filled column down the other.
    private var hero: some View {
        HStack(alignment: .center, spacing: 0) {
            VerticalText("恭喜发财", font: Theme.mincho(9), color: t.ink, spacing: 2)
                .frame(width: 26)

            Spacer(minLength: 0)

            Text(verbatim: "\(info.day)")
                .font(.system(size: 78, weight: .black, design: .serif))
                .foregroundStyle(t.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            Spacer(minLength: 0)

            HStack(spacing: 2) {
                Text(verbatim: weekdayNamesEN[info.weekday])
                    .font(.system(size: 6, weight: .heavy, design: .serif))
                    .tracking(0.6)
                    .rotationEffect(.degrees(90))
                    .fixedSize()
                    .frame(width: 9)
                VerticalText(
                    "星期" + ["日", "一", "二", "三", "四", "五", "六"][info.weekday - 1],
                    font: Theme.mincho(11), color: t.paper, spacing: 2
                )
                .padding(.vertical, 5)
                .padding(.horizontal, 3.5)
                .background(t.ink, in: .rect(cornerRadius: 1))
            }
            .frame(width: 34)
        }
        .frame(height: 104)
    }

    // MARK: - The lunisolar date

    private var lunarLine: some View {
        VStack(spacing: 3) {
            HStack(spacing: 5) {
                Text(verbatim: "农历")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundStyle(t.paper)
                    .padding(.vertical, 2)
                    .padding(.horizontal, 4)
                    .background(t.ink, in: .rect(cornerRadius: 1))
                Text(verbatim: cn(ls.monthName) + ls.monthLengthMark)
                    .font(Theme.mincho(12))
                Text(verbatim: ls.dayName + "日")
                    .font(Theme.mincho(17))
            }
            .foregroundStyle(t.ink)

            // 節氣 and festivals are the calendar's own landmarks; the slot
            // holds its height so the block below never shifts.
            Group {
                if let name = ls.festival ?? ls.solarTerm {
                    Text(verbatim: cn(name))
                        .font(Theme.mincho(8.5))
                        .foregroundStyle(t.paper)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 1)
                        .background(t.ink, in: .rect(cornerRadius: 1))
                } else if let phase = ls.moonPhaseName {
                    Text(verbatim: phase)
                        .font(Theme.mincho(8.5))
                        .foregroundStyle(t.ink)
                }
            }
            .frame(height: 13)
        }
        .padding(.top, 6)
    }

    // MARK: - 宜 / 忌, either side of the wheel

    private var adviceBlock: some View {
        HStack(alignment: .center, spacing: 0) {
            column("宜", am.good.map(cn))
            Spacer(minLength: 0)
            VStack(spacing: 3) {
                BaguaWheel(color: t.ink, size: 58)
                MoonPhaseDisc(
                    illumination: ls.illumination,
                    isWaxing: ls.isWaxing,
                    color: t.ink,
                    size: 12
                )
            }
            Spacer(minLength: 0)
            column("忌", am.bad.map(cn))
        }
        .padding(.top, 8)
        .frame(height: 96)
    }

    private func column(_ head: String, _ items: [String]) -> some View {
        VStack(spacing: 2.5) {
            Text(verbatim: head)
                .font(Theme.mincho(15))
                .foregroundStyle(t.paper)
                .frame(width: 19, height: 19)
                .background(t.ink, in: .rect(cornerRadius: 1))
            ForEach(items, id: \.self) { item in
                Text(verbatim: item)
                    .font(Theme.mincho(8.5))
                    .foregroundStyle(t.ink)
            }
        }
        .frame(width: 54)
    }

    // MARK: - The day's own pillar, and what follows from it

    /// 戊申金虚宿除日 — set as one string, the way the old pages run it together.
    private var pillarRow: some View {
        VStack(spacing: 4) {
            Text(verbatim: cn(am.dayGanzhi + am.element + am.mansionName + am.officerDay))
                .font(Theme.mincho(13))
                .foregroundStyle(t.paper)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 3)
                .background(t.ink, in: .rect(cornerRadius: 1))

            HStack(spacing: 0) {
                Text(verbatim: "吉时 " + openHours)
                    .font(Theme.mincho(8.5))
                    .frame(maxWidth: .infinity)
            }
            .foregroundStyle(t.ink)

            HStack(spacing: 0) {
                ForEach([
                    "冲" + cn(am.clashAnimal),
                    "煞" + cn(am.evilDirection),
                    "财神" + cn(am.wealthDirection),
                    "喜神" + cn(am.joyDirection),
                ], id: \.self) { part in
                    Text(verbatim: part)
                        .font(Theme.mincho(8))
                        .frame(maxWidth: .infinity)
                }
            }
            .foregroundStyle(t.ink)
        }
        .padding(.top, 8)
    }

    /// The open double-hours run together — 子丑寅巳申酉 — as the old pages set
    /// them, rather than the 通勝 page's grid. Branch names are script-neutral.
    private var openHours: String {
        (0..<12)
            .filter { am.hourIsAuspicious(branch: $0) }
            .map { Ganzhi.hourNames[$0] }
            .joined()
    }

    // MARK: - Footer

    private var footer: some View {
        HStack(spacing: 0) {
            Text(verbatim: "宜忌依黄历")
                .font(Theme.mincho(7))
                .foregroundStyle(t.ink.opacity(0.75))
            Spacer(minLength: 0)
            Text(verbatim: "黄历")
                .font(Theme.mincho(10))
                .foregroundStyle(t.paper)
                .frame(width: 20, height: 20)
                .background(t.ink.opacity(0.9), in: .rect(cornerRadius: 2))
                .rotationEffect(.degrees(-2))
        }
    }
}
