//
//  OnboardingLayout.swift
//  himekuri
//
//  A lesson page, printed in the selected theme's ink so it reads as part of
//  the pad rather than a dialog laid over it.
//

import SwiftUI

struct OnboardingLayout: View {
    let page: OnboardingPage
    let t: PageTheme

    var body: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 30)

            Text(verbatim: page.kicker)
                .font(.system(size: 8.5, weight: .semibold))
                .tracking(3.5)
                .foregroundStyle(t.ink.opacity(0.55))

            Rectangle()
                .fill(t.ink.opacity(0.3))
                .frame(width: Metrics.pageW - 72, height: 0.6)
                .padding(.top, 9)

            Spacer(minLength: 4)

            // A fixed band for the diagram, so the headline lands in the same
            // place on both lessons however tall the drawing above it is.
            diagram
                .frame(height: 100)

            Spacer(minLength: 4)

            Text(verbatim: page.headline)
                .font(.system(size: 24, weight: .heavy, design: .serif))
                .foregroundStyle(t.ink)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.6)

            Text(verbatim: page.note)
                .font(.system(size: 10.5))
                .lineSpacing(3.5)
                .multilineTextAlignment(.center)
                .foregroundStyle(t.ink.opacity(0.7))
                .frame(width: 198)
                // Without this the page's own height can squeeze the wrapped
                // text back to one truncated line.
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 10)

            Spacer()

            if let closer = page.closer {
                VStack(spacing: 2) {
                    Text(verbatim: closer)
                        .font(.system(size: 12.5, weight: .heavy))
                        .multilineTextAlignment(.center)
                        .lineSpacing(1)
                        .foregroundStyle(t.accentRed)
                        .frame(width: 196)
                        .fixedSize(horizontal: false, vertical: true)
                    // The same leader arrow as the menu-bar cue, turned around:
                    // up for where the themes are, down for how to get on.
                    VStack(spacing: 0) {
                        Rectangle()
                            .fill(t.accentRed)
                            .frame(width: 1, height: 13)
                        Image(systemName: "arrowtriangle.down.fill")
                            .font(.system(size: 8))
                            .foregroundStyle(t.accentRed)
                    }
                    .padding(.top, 4)
                }
                .padding(.bottom, 12)
            }

            Rectangle()
                .fill(t.accentRed)
                .frame(width: 34, height: 2.5)

            HStack(spacing: 6) {
                Text(verbatim: page.step)
                    .font(.system(size: 8, weight: .bold).monospacedDigit())
                    .foregroundStyle(t.accentRed)
                Text(verbatim: page.footer)
                    .font(.system(size: 8, weight: .medium))
                    .foregroundStyle(t.ink.opacity(0.55))
            }
            .padding(.top, 9)

            Spacer().frame(height: 18)
        }
        .padding(.horizontal, 24)
    }

    @ViewBuilder
    private var diagram: some View {
        switch page {
        case .pull: pullDiagram
        case .prints: menuBarDiagram
        }
    }

    // MARK: - Diagrams

    /// The pad in miniature: staples, the seam the paper parts along, and the
    /// direction of the pull that gets it there.
    private var pullDiagram: some View {
        HStack(spacing: 16) {
            ZStack(alignment: .top) {
                RoundedRectangle(cornerRadius: 1.5)
                    .stroke(t.ink.opacity(0.4), lineWidth: 0.8)
                    .frame(width: 54, height: 74)

                HStack(spacing: 18) {
                    ForEach(0..<2, id: \.self) { _ in
                        Rectangle()
                            .fill(t.ink.opacity(0.5))
                            .frame(width: 5, height: 1.6)
                    }
                }
                .padding(.top, 5)

                // The tear line, dashed the way a print diagram would mark it.
                Path { p in
                    p.move(to: .zero)
                    p.addLine(to: CGPoint(x: 54, y: 0))
                }
                .stroke(t.accentRed, style: StrokeStyle(lineWidth: 0.9, dash: [3, 2.5]))
                .frame(width: 54, height: 1)
                .padding(.top, 12)
            }

            VStack(spacing: 1) {
                Text(verbatim: page.cue)
                    .font(.system(size: 9, weight: .heavy))
                    .tracking(2)
                    .foregroundStyle(t.accentRed)
                    .padding(.bottom, 3)
                ForEach(0..<3, id: \.self) { i in
                    Image(systemName: "chevron.compact.down")
                        .font(.system(size: 22 - CGFloat(i) * 4, weight: .light))
                        .foregroundStyle(t.accentRed.opacity(0.85 - Double(i) * 0.25))
                }
            }
        }
    }

    /// The menu bar as it sits above the pad, with our calendar ringed and the
    /// arrow pointing back up at it.
    private var menuBarDiagram: some View {
        let stripW: CGFloat = 170
        let lead: CGFloat = 9
        let iconW: CGFloat = 18

        return VStack(spacing: 7) {
            HStack(spacing: 10) {
                Image(systemName: "calendar")
                    .font(.system(size: 9.5, weight: .semibold))
                    .foregroundStyle(t.accentRed)
                    .frame(width: iconW, height: iconW)
                    .overlay(
                        RoundedRectangle(cornerRadius: 2.5)
                            .stroke(t.accentRed, lineWidth: 0.9)
                    )
                Image(systemName: "wifi")
                Image(systemName: "battery.100")
                Text(verbatim: "9:41")
                    .font(.system(size: 7.5, weight: .medium).monospacedDigit())
                Spacer(minLength: 0)
            }
            .font(.system(size: 8, weight: .medium))
            .foregroundStyle(t.ink.opacity(0.45))
            .padding(.leading, lead)
            .frame(width: stripW, height: 20)
            .background(
                RoundedRectangle(cornerRadius: 3)
                    .fill(t.ink.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 3)
                            .stroke(t.ink.opacity(0.3), lineWidth: 0.7)
                    )
            )

            // Aligned under the ringed icon rather than centred on the strip.
            HStack(spacing: 0) {
                VStack(spacing: 0) {
                    // A leader arrow back up to the icon — a pointer, where the
                    // tear page's chevrons are motion.
                    Image(systemName: "arrowtriangle.up.fill")
                        .font(.system(size: 8))
                        .foregroundStyle(t.accentRed)
                    Rectangle()
                        .fill(t.accentRed)
                        .frame(width: 1, height: 14)
                    Text(verbatim: page.cue)
                        .font(.system(size: 8, weight: .heavy))
                        .tracking(1.2)
                        .foregroundStyle(t.accentRed)
                        .fixedSize()
                        .padding(.top, 3)
                }
                .frame(width: iconW)
                Spacer(minLength: 0)
            }
            .padding(.leading, lead)
            .frame(width: stripW)
        }
    }
}
