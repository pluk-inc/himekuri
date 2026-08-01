//
//  HuangliLayout.swift
//  himekuri
//
//  黄历 — the Chinese almanac page: sexagenary year and zodiac, the lunar
//  date in 初/廿 numerals, framed in red the way a street-corner huangli is.
//

import SwiftUI

struct HuangliLayout: View {
    let info: DayInfo
    let t: PageTheme

    var body: some View {
        ZStack {
            // The double red frame of a printed almanac.
            Rectangle()
                .strokeBorder(t.accentRed.opacity(0.85), lineWidth: 2.5)
                .padding(8)
            Rectangle()
                .strokeBorder(t.accentRed.opacity(0.85), lineWidth: 0.8)
                .padding(13)

            VStack(spacing: 0) {
                Spacer().frame(height: 30)

                Text(verbatim: "公历 \(info.year)年\(info.month)月")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(t.ink.opacity(0.7))

                HStack(spacing: 10) {
                    Text(verbatim: info.ganzhiYear)
                        .font(Theme.mincho(15))
                    Text(verbatim: "【\(info.zodiac)】")
                        .font(.system(size: 13, weight: .bold))
                }
                .foregroundStyle(t.accentRed)
                .padding(.top, 6)

                Text(verbatim: "\(info.day)")
                    .font(Theme.numeral(info.day < 10 ? 140 : 116))
                    .foregroundStyle(t.accent(for: info))
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                    .frame(height: 150)
                    .padding(.top, 2)

                Text(verbatim: "星期\(["日", "一", "二", "三", "四", "五", "六"][info.weekday - 1])")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(t.accent(for: info))

                // The lunar date, boxed — the almanac's reason to exist.
                HStack(spacing: 4) {
                    Text(verbatim: "农历")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(t.paper)
                        .padding(.vertical, 3)
                        .padding(.horizontal, 5)
                        .background(t.accentRed.opacity(0.9), in: .rect(cornerRadius: 2))
                    Text(verbatim: "\(info.lunarMonthCN)\(info.lunarDayCN)")
                        .font(Theme.mincho(15))
                        .foregroundStyle(t.ink)
                        .padding(.horizontal, 4)
                }
                .padding(.top, 10)

                Spacer()

                Rectangle()
                    .fill(t.accentRed.opacity(0.5))
                    .frame(width: Metrics.pageW - 80, height: 0.6)
                    .padding(.bottom, 7)

                MonthGrid(info: info, t: t, customHeaders: ["日", "一", "二", "三", "四", "五", "六"])

                Spacer().frame(height: 22)
            }
        }
    }
}
