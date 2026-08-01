//
//  Shapes.swift
//  himekuri
//
//  Jagged tear geometry. A torn piece and its stub share a seed so the
//  fibrous edges are complements of each other.
//

import SwiftUI

/// Generates the jagged tear-line y offsets for a given seed and width.
///
/// Every tear is different: about a third are *perfect* — the fibers part
/// right along the binding and leave nothing visible — while the rest leave
/// ragged remnants in patches, the way real paper lets go unevenly.
/// (The binding hides everything at or above `tearY`, so a hidden edge
/// simply reads as a clean tear.)
nonisolated func tearEdgePoints(seed: UInt64, width: CGFloat) -> [CGPoint] {
    var rng = SeededRandom(seed: seed)
    let base = Metrics.tearY
    let clean = rng.unit() < 0.35

    var y = base + (clean ? rng.cg(-2...1) : rng.cg(-3...5))
    var points: [CGPoint] = [CGPoint(x: 0, y: min(y, base + 9))]
    var inPatch = rng.unit() < 0.5
    var x: CGFloat = 0
    while x < width {
        x = min(x + rng.cg(6...16), width)
        if clean {
            // Right along the perforation, barely a fiber out of place.
            y = base + rng.cg(-2...2)
        } else {
            // Fringe patches come and go across the width.
            if rng.unit() < 0.12 { inPatch.toggle() }
            let target = inPatch ? base + rng.cg(4...9) : base + rng.cg(-4...1)
            y = (y + target) / 2 + rng.cg(-1.5...1.5)
        }
        // Keep the remnant clear of the printed header below it.
        points.append(CGPoint(x: x, y: min(y, base + 9)))
    }
    return points
}

/// The piece that falls: full page below a jagged top edge.
nonisolated struct TornPieceShape: Shape {
    let seed: UInt64

    func path(in rect: CGRect) -> Path {
        var p = Path()
        let edge = tearEdgePoints(seed: seed, width: rect.width)
        p.move(to: edge[0])
        for pt in edge.dropFirst() { p.addLine(to: pt) }
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        p.closeSubpath()
        return p
    }
}

/// The remnant left under the staples: jagged bottom edge, same seed.
nonisolated struct StubShape: Shape {
    let seed: UInt64

    func path(in rect: CGRect) -> Path {
        var p = Path()
        let edge = tearEdgePoints(seed: seed, width: rect.width)
        p.move(to: CGPoint(x: rect.minX, y: rect.minY))
        p.addLine(to: edge[0])
        for pt in edge.dropFirst() { p.addLine(to: pt) }
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        p.closeSubpath()
        return p
    }
}

/// Just the torn edge polyline — stroked to catch the light on loose fibers.
nonisolated struct TearEdgeLine: Shape {
    let seed: UInt64

    func path(in rect: CGRect) -> Path {
        var p = Path()
        let edge = tearEdgePoints(seed: seed, width: rect.width)
        p.move(to: edge[0])
        for pt in edge.dropFirst() { p.addLine(to: pt) }
        return p
    }
}
