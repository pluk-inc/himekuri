//
//  PaperGrain.swift
//  himekuri
//
//  Subtle paper fiber: seeded specks, unique per day so pages differ slightly.
//

import SwiftUI

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
