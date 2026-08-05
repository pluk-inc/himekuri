//
//  PadStack.swift
//  himekuri
//
//  The unturned pages beneath the top sheet, thicker while the year is young.
//

import SwiftUI

struct PadStack: View {
    let remainingFraction: Double
    let theme: PageTheme

    var body: some View {
        let layers = max(4, Int(remainingFraction * 22))
        return ZStack(alignment: .top) {
            ForEach(0..<layers, id: \.self) { i in
                let depth = CGFloat(layers - i)
                RoundedRectangle(cornerRadius: 2)
                    .fill(theme.paper.blended(with: theme.edge, by: Double(depth) / Double(layers) * 0.9))
                    .frame(width: Metrics.pageW, height: Metrics.pageH)
                    .offset(x: depth * 0.55, y: Metrics.pageTopInset + depth * 0.85)
            }
        }
        .compositingGroup()
        .opacity(theme.paperOpacity)
        .allowsHitTesting(false)
    }
}
