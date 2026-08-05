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
    /// Set on the lesson pages a fresh pad opens with: they print in place of
    /// the date, in the same ink.
    var onboarding: OnboardingPage? = nil

    /// The almanac themes print on stock thin enough to see the desk through.
    /// The lessons are an insert on heavier paper: sparse text over a dense
    /// almanac page showing through reads as a rendering fault, not as paper.
    private var paperOpacity: Double {
        onboarding == nil ? theme.paperOpacity : 1
    }

    var body: some View {
        ZStack {
            theme.paper.opacity(paperOpacity)
            // Thin stock: tomorrow's print ghosts faintly through the sheet.
            // A lesson page has no day behind it to show through.
            if theme.showThrough > 0, onboarding == nil {
                let cal = Calendar.current
                let tomorrow = DayInfo(date: cal.date(byAdding: .day, value: 1, to: info.date) ?? info.date)
                layout(for: tomorrow)
                    .opacity(theme.showThrough)
                    .blur(radius: 0.7)
                    .allowsHitTesting(false)
            }
            // The lessons sit above today, so their grain is offset off the
            // same seed — otherwise the pages would share a fibre pattern.
            PaperGrain(seed: info.dayOfYear + (onboarding.map { 900 + $0.rawValue } ?? 0),
                       strength: theme.grainStrength)
            if let onboarding {
                OnboardingLayout(page: onboarding, t: theme)
            } else {
                layout(for: info)
            }
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
        case .tongsheng: TongshengLayout(info: info, t: theme)
        }
    }
}
