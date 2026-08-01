//
//  ThemeLayouts.swift
//  himekuri
//
//  The non-default print styles: Swiss, Brutalist, Retro Office, Koyomi.
//

import SwiftUI

// MARK: - Minimal Swiss

struct SwissLayout: View {
    let info: DayInfo
    let t: PageTheme

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Spacer().frame(height: 36)

            HStack(alignment: .firstTextBaseline) {
                Text(verbatim: monthNamesEN[info.month])
                    .font(.system(size: 11, weight: .bold))
                    .tracking(3)
                Spacer()
                Text(verbatim: "\(info.year)")
                    .font(.system(size: 11, weight: .medium).monospacedDigit())
            }
            .foregroundStyle(t.ink)

            Rectangle().fill(t.ink).frame(height: 1).padding(.top, 6)

            Text(verbatim: "\(info.day)")
                .font(.system(size: 150, weight: .heavy))
                .kerning(-4)
                .foregroundStyle(t.accent(for: info))
                .padding(.leading, -6)
                .frame(height: 150, alignment: .topLeading)
                .padding(.top, 18)

            Text(verbatim: weekdayNamesEN[info.weekday])
                .font(.system(size: 13, weight: .heavy))
                .tracking(4)
                .foregroundStyle(t.accent(for: info))
                .padding(.top, 14)

            Text(verbatim: "WEEK \(info.weekOfYear) · DAY \(info.dayOfYear) OF \(totalDays(of: info))")
                .font(.system(size: 8, weight: .medium).monospacedDigit())
                .tracking(1)
                .foregroundStyle(t.ink.opacity(0.55))
                .padding(.top, 4)

            Spacer()

            Rectangle().fill(t.accentRed).frame(width: 44, height: 3)

            HStack(alignment: .bottom) {
                Text(verbatim: info.proverb.en)
                    .font(.system(size: 8, weight: .regular))
                    .foregroundStyle(t.ink.opacity(0.65))
                    .frame(width: 118, alignment: .leading)
                Spacer()
                MonthGrid(info: info, t: t, design: .default, latinHeader: true)
            }
            .padding(.top, 12)

            Spacer().frame(height: 18)
        }
        .padding(.horizontal, 22)
    }
}

// MARK: - Brutalist

struct BrutalistLayout: View {
    let info: DayInfo
    let t: PageTheme

    var body: some View {
        ZStack {
            Rectangle()
                .strokeBorder(t.ink, lineWidth: 4)
                .padding(9)

            VStack(spacing: 0) {
                Spacer().frame(height: 34)

                HStack(spacing: 0) {
                    tag("\(info.year)")
                    tag(String(format: "%02d", info.month))
                    tag(info.weekdayEN)
                }

                Text(verbatim: "\(info.day)")
                    .font(.system(size: info.day < 10 ? 200 : 158, weight: .black, design: .monospaced))
                    .kerning(info.day < 10 ? 0 : -12)
                    .foregroundStyle(t.accent(for: info))
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                    .frame(height: 190)

                Text(verbatim: weekdayNamesEN[info.weekday])
                    .font(.system(size: 15, weight: .black, design: .monospaced))
                    .tracking(3)
                    .foregroundStyle(t.paper)
                    .padding(.vertical, 5)
                    .frame(maxWidth: .infinity)
                    .background(t.ink)
                    .padding(.horizontal, 26)

                Text(verbatim: "DAY \(info.dayOfYear)/\(totalDays(of: info)) — NO WAY BACK")
                    .font(.system(size: 8, weight: .bold, design: .monospaced))
                    .tracking(1)
                    .foregroundStyle(t.ink)
                    .padding(.top, 8)

                Spacer()

                MonthGrid(info: info, t: t, design: .monospaced, latinHeader: true)

                Spacer().frame(height: 24)
            }
        }
    }

    private func tag(_ s: String) -> some View {
        Text(verbatim: s)
            .font(.system(size: 11, weight: .black, design: .monospaced))
            .foregroundStyle(t.ink)
            .padding(.vertical, 3)
            .padding(.horizontal, 8)
            .overlay(Rectangle().stroke(t.ink, lineWidth: 1.5))
    }
}

// MARK: - Retro Office

struct OfficeLayout: View {
    let info: DayInfo
    let t: PageTheme

    var body: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 32)

            HStack(spacing: 8) {
                rule
                Text(verbatim: monthNamesEN[info.month])
                    .font(.system(size: 13, weight: .bold, design: .serif))
                    .tracking(4)
                rule
            }
            .foregroundStyle(t.ink)
            .padding(.horizontal, 26)

            Text(verbatim: "\(info.year)")
                .font(.system(size: 10, weight: .semibold, design: .serif))
                .tracking(6)
                .foregroundStyle(t.ink.opacity(0.7))
                .padding(.top, 3)

            doubleRule
                .padding(.horizontal, 34)
                .padding(.top, 8)

            Text(verbatim: "\(info.day)")
                .font(.system(size: info.day < 10 ? 150 : 128, weight: .black, design: .serif))
                .foregroundStyle(t.accent(for: info))
                .lineLimit(1)
                .frame(height: 158)
                .padding(.top, 6)

            Text(verbatim: weekdayNamesEN[info.weekday])
                .font(.system(size: 12, weight: .semibold, design: .serif))
                .tracking(3.5)
                .foregroundStyle(t.accent(for: info))

            Text(verbatim: "\(ordinal(info.dayOfYear)) DAY · \(totalDays(of: info) - info.dayOfYear) REMAINING")
                .font(.system(size: 7.5, weight: .medium, design: .serif))
                .tracking(1.5)
                .foregroundStyle(t.ink.opacity(0.55))
                .padding(.top, 5)

            Spacer()

            Text(verbatim: "“\(info.proverb.en)”")
                .font(.system(size: 9.5, weight: .regular, design: .serif).italic())
                .foregroundStyle(t.ink.opacity(0.8))
                .padding(.horizontal, 30)
                .multilineTextAlignment(.center)

            doubleRule
                .padding(.horizontal, 60)
                .padding(.vertical, 8)

            MonthGrid(info: info, t: t, design: .serif, latinHeader: true)

            Spacer().frame(height: 14)
        }
    }

    private var rule: some View {
        Rectangle().fill(t.ink.opacity(0.7)).frame(height: 0.8)
    }

    private var doubleRule: some View {
        VStack(spacing: 1.5) {
            Rectangle().fill(t.ink.opacity(0.8)).frame(height: 1.2)
            Rectangle().fill(t.ink.opacity(0.8)).frame(height: 0.5)
        }
    }

    private func ordinal(_ n: Int) -> String {
        let suffix: String
        switch (n % 100, n % 10) {
        case (11...13, _): suffix = "TH"
        case (_, 1): suffix = "ST"
        case (_, 2): suffix = "ND"
        case (_, 3): suffix = "RD"
        default: suffix = "TH"
        }
        return "\(n)\(suffix)"
    }
}

// MARK: - Koyomi (traditional lunar almanac)

struct KoyomiLayout: View {
    let info: DayInfo
    let t: PageTheme

    var body: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 34)

            HStack(alignment: .top, spacing: 0) {
                // Left: weekday and rokuyō, boxed in red.
                VStack(spacing: 12) {
                    VerticalText(info.weekdayKanji, font: Theme.mincho(19), color: t.accent(for: info), spacing: 3)
                    VerticalText(info.rokuyo, font: Theme.mincho(13), color: t.accentRed, spacing: 2)
                        .padding(.vertical, 5)
                        .padding(.horizontal, 4)
                        .overlay(Rectangle().stroke(t.accentRed, lineWidth: 1))
                }
                .frame(width: 58)
                .padding(.top, 8)

                Spacer(minLength: 0)

                // Center: the day, written in kanji.
                VStack(spacing: 8) {
                    VerticalText(
                        kanjiNumber(info.day),
                        font: Theme.mincho(info.day >= 20 ? 52 : 64),
                        color: t.accent(for: info),
                        spacing: 0
                    )
                    Text(verbatim: "(\(info.day))")
                        .font(.system(size: 11, weight: .semibold, design: .serif).monospacedDigit())
                        .foregroundStyle(t.ink.opacity(0.6))
                }
                .frame(height: 250, alignment: .top)

                Spacer(minLength: 0)

                // Right: era year and month, the tallest column.
                VStack(spacing: 12) {
                    VerticalText(info.reiwa, font: Theme.mincho(12), color: t.ink, spacing: 1)
                    VerticalText(kanjiNumber(info.month) + "月", font: Theme.mincho(24), color: t.ink, spacing: 2)
                }
                .frame(width: 58)
                .padding(.top, 8)
            }
            .padding(.horizontal, 18)

            Spacer(minLength: 2)

            // Old-calendar date.
            Text(verbatim: "旧暦 \(kanjiNumber(info.lunarMonth))月\(kanjiNumber(info.lunarDay))日")
                .font(Theme.mincho(10))
                .foregroundStyle(t.ink.opacity(0.75))

            Text(verbatim: info.proverb.jp)
                .font(Theme.mincho(11))
                .foregroundStyle(t.ink)
                .padding(.top, 5)

            Rectangle()
                .fill(t.ink.opacity(0.5))
                .frame(width: Metrics.pageW - 70, height: 0.6)
                .padding(.vertical, 7)

            HStack(alignment: .bottom) {
                MonthGrid(info: info, t: t)
                    .frame(maxWidth: .infinity)
            }
            .overlay(alignment: .bottomTrailing) {
                seal.padding(.trailing, 20)
            }

            Spacer().frame(height: 12)
        }
    }

    /// A red hanko seal.
    private var seal: some View {
        Text(verbatim: "暦")
            .font(Theme.mincho(13))
            .foregroundStyle(t.paper)
            .frame(width: 22, height: 22)
            .background(t.accentRed.opacity(0.9), in: .rect(cornerRadius: 2))
            .rotationEffect(.degrees(-2))
    }
}
