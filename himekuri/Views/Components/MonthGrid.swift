//
//  MonthGrid.swift
//  himekuri
//
//  The mini month calendar printed at the foot of every page.
//

import SwiftUI

struct MonthGrid: View {
    let info: DayInfo
    let t: PageTheme
    var design: Font.Design = .serif
    var latinHeader = false
    /// Override the weekday header glyphs (e.g. 日一二…六 for the huangli).
    var customHeaders: [String]? = nil

    var body: some View {
        let headers = customHeaders ?? (latinHeader
            ? ["S", "M", "T", "W", "T", "F", "S"]
            : ["日", "月", "火", "水", "木", "金", "土"])
        // Stacks rather than `Grid` (macOS 13+): every column here is a fixed
        // 12pt anyway, so the grid was never doing any work worth its minimum.
        VStack(spacing: 2.5) {
            HStack(spacing: 7.5) {
                ForEach(0..<7, id: \.self) { i in
                    Text(verbatim: headers[i])
                        .font(latinHeader
                            ? .system(size: 7, weight: .bold, design: design)
                            : Theme.kanji(7))
                        .foregroundStyle(columnColor(i))
                        .frame(width: 12)
                }
            }
            ForEach(info.grid.indices, id: \.self) { r in
                HStack(spacing: 7.5) {
                    ForEach(0..<7, id: \.self) { c in
                        cell(info.grid[r][c], column: c)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func cell(_ d: Int?, column c: Int) -> some View {
        if let d {
            let isToday = d == info.day
            Text(verbatim: "\(d)")
                .font(.system(size: 8, weight: isToday ? .black : .semibold, design: design).monospacedDigit())
                .foregroundStyle(isToday ? t.paper : columnColor(c))
                .frame(width: 12, height: 11)
                .background(
                    isToday ? AnyShapeStyle(t.accent(for: info)) : AnyShapeStyle(.clear),
                    in: RoundedRectangle(cornerRadius: 2)
                )
        } else {
            Color.clear.frame(width: 12, height: 11)
        }
    }

    private func columnColor(_ c: Int) -> Color {
        c == 0 ? t.sunday : c == 6 ? t.saturday : t.ink
    }
}
