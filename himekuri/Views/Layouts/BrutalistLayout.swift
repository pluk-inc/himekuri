//
//  BrutalistLayout.swift
//  himekuri
//
//  Heavy mono blocks, no apologies.
//

import SwiftUI

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
