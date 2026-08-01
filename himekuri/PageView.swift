//
//  PageView.swift
//  himekuri
//
//  One printed page of the pad, rendered in the selected print style.
//

import SwiftUI

extension DayInfo {
    var accentColor: Color { PageTheme.showa.accent(for: self) }
}

struct PageView: View {
    let info: DayInfo
    var theme: PageTheme = .showa

    var body: some View {
        ZStack {
            theme.paper
            // Thin stock: tomorrow's print ghosts faintly through the sheet.
            if theme.showThrough > 0 {
                let cal = Calendar.current
                let tomorrow = DayInfo(date: cal.date(byAdding: .day, value: 1, to: info.date) ?? info.date)
                layout(for: tomorrow)
                    .opacity(theme.showThrough)
                    .blur(radius: 0.7)
                    .allowsHitTesting(false)
            }
            PaperGrain(seed: info.dayOfYear, strength: theme.grainStrength)
            layout(for: info)
        }
        .frame(width: Metrics.pageW, height: Metrics.pageH)
        .clipShape(RoundedRectangle(cornerRadius: 2))
    }

    @ViewBuilder
    private func layout(for info: DayInfo) -> some View {
        switch theme {
        case .showa: ShowaLayout(info: info, t: theme)
        case .swiss: SwissLayout(info: info, t: theme)
        case .brutalist: BrutalistLayout(info: info, t: theme)
        case .office: OfficeLayout(info: info, t: theme)
        case .koyomi: KoyomiLayout(info: info, t: theme)
        }
    }
}

// MARK: - Shared pieces

/// Subtle paper fiber: seeded specks, unique per day so pages differ slightly.
struct PaperGrain: View {
    let seed: Int
    var strength: Double = 1.0

    var body: some View {
        Canvas { ctx, size in
            var rng = SeededRandom(seed: UInt64(seed) &* 0x2545F4914F6CDD1D &+ 11)
            for _ in 0..<380 {
                let x = rng.cg(0...size.width)
                let y = rng.cg(0...size.height)
                let r = rng.cg(0.3...0.9)
                let a = Double(rng.range(0.02...0.07)) * strength
                ctx.fill(
                    Path(ellipseIn: CGRect(x: x, y: y, width: r, height: r)),
                    with: .color(Ink.grain.opacity(a))
                )
            }
        }
        .allowsHitTesting(false)
    }
}

struct VerticalText: View {
    let text: String
    let font: Font
    var color: Color = Ink.black
    var spacing: CGFloat = 0

    init(_ text: String, font: Font, color: Color = Ink.black, spacing: CGFloat = 0) {
        self.text = text
        self.font = font
        self.color = color
        self.spacing = spacing
    }

    var body: some View {
        VStack(spacing: spacing) {
            ForEach(Array(text.enumerated()), id: \.offset) { _, ch in
                Text(String(ch)).font(font)
            }
        }
        .foregroundStyle(color)
    }
}

struct MonthGrid: View {
    let info: DayInfo
    let t: PageTheme
    var design: Font.Design = .serif
    var latinHeader = false

    var body: some View {
        let headers = latinHeader
            ? ["S", "M", "T", "W", "T", "F", "S"]
            : ["日", "月", "火", "水", "木", "金", "土"]
        Grid(horizontalSpacing: 7.5, verticalSpacing: 2.5) {
            GridRow {
                ForEach(0..<7, id: \.self) { i in
                    Text(verbatim: headers[i])
                        .font(latinHeader
                            ? .system(size: 7, weight: .bold, design: design)
                            : Theme.kanji(7))
                        .foregroundStyle(columnColor(i))
                }
            }
            ForEach(info.grid.indices, id: \.self) { r in
                GridRow {
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
                    in: .rect(cornerRadius: 2)
                )
        } else {
            Color.clear.frame(width: 12, height: 11)
        }
    }

    private func columnColor(_ c: Int) -> Color {
        c == 0 ? t.sunday : c == 6 ? t.saturday : t.ink
    }
}

// MARK: - Shōwa Print (the original)

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

nonisolated func totalDays(of info: DayInfo) -> Int {
    Calendar(identifier: .gregorian).range(of: .day, in: .year, for: info.date)?.count ?? 365
}

nonisolated let monthNamesEN = [
    "", "JANUARY", "FEBRUARY", "MARCH", "APRIL", "MAY", "JUNE",
    "JULY", "AUGUST", "SEPTEMBER", "OCTOBER", "NOVEMBER", "DECEMBER",
]

nonisolated let weekdayNamesEN = [
    "", "SUNDAY", "MONDAY", "TUESDAY", "WEDNESDAY", "THURSDAY", "FRIDAY", "SATURDAY",
]
