//
//  PadStubs.swift
//  himekuri
//
//  Remnants under the staples: slivers of torn pages, layered, with loose
//  fibers catching the light along the newest edge.
//

import SwiftUI

struct PadStubs: View {
    let tornCount: Int
    let theme: PageTheme

    var body: some View {
        let lastSeed = tearSeed(for: tornCount - 1)
        ZStack(alignment: .top) {
            // An older, slightly deeper sliver peeking out beneath.
            if tornCount > 1 {
                StubShape(seed: tearSeed(for: tornCount - 2))
                    .fill(theme.paper.mix(with: theme.edge, by: 0.5))
                    .offset(y: 1.4)
            }
            StubShape(seed: lastSeed)
                .fill(theme.paper.mix(with: theme.edge, by: 0.15))
                .shadow(color: .black.opacity(0.10), radius: 1.4, y: 1)
            TearEdgeLine(seed: lastSeed)
                .stroke(Color.white.opacity(0.5), lineWidth: 0.7)
        }
        .frame(width: Metrics.pageW, height: 36)
        .allowsHitTesting(false)
    }
}
