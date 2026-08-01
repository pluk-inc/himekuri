//
//  OfficeLayout.swift
//  himekuri
//
//  A retro American memo-pad calendar.
//

import SwiftUI

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
