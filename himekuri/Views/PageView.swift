//
//  PageView.swift
//  himekuri
//
//  One printed page of the pad, rendered in the selected print style.
//

import SwiftUI

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
        case .huangli: HuangliLayout(info: info, t: theme)
        }
    }
}
