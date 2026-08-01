//
//  ShowaLayout.swift
//  himekuri
//
//  1960s Japanese print — the default page.
//

import SwiftUI

struct ShowaLayout: View {
    let info: DayInfo
    let t: PageTheme

    var body: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 32)

            Text(verbatim: "\(info.year)")
                .font(.system(size: 21, weight: .heavy, design: .serif))
                .tracking(7)
                .foregroundStyle(t.ink)

            HStack(alignment: .top, spacing: 0) {
                leftColumn
                    .frame(width: 62)
                    .padding(.top, 14)
                Spacer(minLength: 0)
                Text(verbatim: "\(info.day)")
                    .font(Theme.numeral(info.day < 10 ? 158 : 122))
                    .foregroundStyle(t.accent(for: info))
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                    .frame(height: 176)
                Spacer(minLength: 0)
                rightColumn
                    .frame(width: 62)
                    .padding(.top, 6)
            }
            .padding(.horizontal, 12)

            Spacer(minLength: 4)

            dayCountLine
                .padding(.bottom, 10)

            VStack(spacing: 2) {
                Text(verbatim: info.proverb.jp)
                    .font(Theme.mincho(11.5))
                    .foregroundStyle(t.ink)
                Text(verbatim: info.proverb.en.uppercased())
                    .font(.system(size: 6.5, weight: .semibold))
                    .tracking(1.2)
                    .foregroundStyle(t.ink.opacity(0.55))
            }

            Rectangle()
                .fill(t.ink.opacity(0.55))
                .frame(width: Metrics.pageW - 60, height: 0.6)
                .padding(.vertical, 6)

            MonthGrid(info: info, t: t)

            Spacer().frame(height: 12)
        }
    }

    private var leftColumn: some View {
        VStack(spacing: 6) {
            VerticalText(info.weekdayKanji, font: Theme.kanji(24), color: t.accent(for: info), spacing: 2)
            Text(verbatim: "(\(info.weekdayEN))")
                .font(.system(size: 9, weight: .heavy))
                .tracking(1)
                .foregroundStyle(t.accent(for: info))
        }
    }

    private var rightColumn: some View {
        VStack(spacing: 10) {
            VerticalText(info.reiwa, font: Theme.mincho(11), color: t.ink, spacing: 1)
            VStack(spacing: 0) {
                Text(verbatim: "\(info.month)")
                    .font(.system(size: 30, weight: .black, design: .serif))
                Text(verbatim: "月")
                    .font(Theme.kanji(21))
            }
            .foregroundStyle(t.ink)
            VerticalText(info.rokuyo, font: Theme.mincho(12), color: t.accentRed, spacing: 1)
                .padding(.vertical, 4)
                .padding(.horizontal, 3)
                .overlay(RoundedRectangle(cornerRadius: 1).stroke(t.accentRed, lineWidth: 0.8))
        }
    }

    private var dayCountLine: some View {
        let total = totalDays(of: info)
        return Text(verbatim: "一年の第\(info.dayOfYear)日 ・ 残り\(total - info.dayOfYear)日")
            .font(Theme.mincho(8.5))
            .foregroundStyle(t.ink.opacity(0.65))
    }
}
