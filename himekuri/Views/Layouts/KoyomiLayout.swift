//
//  KoyomiLayout.swift
//  himekuri
//
//  The traditional lunar almanac.
//

import SwiftUI

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
