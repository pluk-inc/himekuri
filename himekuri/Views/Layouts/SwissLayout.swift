//
//  SwissLayout.swift
//  himekuri
//
//  Minimal Swiss typography: one number, set heavy.
//

import SwiftUI

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
