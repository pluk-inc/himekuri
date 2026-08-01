//
//  PaperSim.swift
//  himekuri
//
//  Real paper physics in the spirit of Ghassaei's Origami Simulator:
//  a verlet-integrated grid with inextensible distance constraints, stiff
//  bending constraints, and breakable fibers along the staple seam.
//  Simulated in 3D — the bulge toward the viewer is what shortens the
//  on-screen projection, exactly like real paper — and rendered by warping
//  the printed page with SKWarpGeometryGrid.
//

import SpriteKit
import SwiftUI
import simd

// MARK: - Solver

@MainActor
final class PaperSim {
    static let cols = 11
    static let rows = 14 // row 0: page top edge; row 1: the tear line; then down

    private(set) var pos: [SIMD3<Float>] = []
    private var prev: [SIMD3<Float>] = []
    private var home: [SIMD3<Float>] = []

    private struct Constraint {
        let a: Int
        let b: Int
        let rest: Float
        let k: Float
    }

    private var constraints: [Constraint] = []
    /// Per-column: does the fiber at the tear line still hold the page?
    private var fiberIntact = [Bool](repeating: true, count: cols)
    private var grabIndex: Int?
    private var grabTarget = SIMD3<Float>(0, 0, 0)
    private var sleeping = true

    private let W = Float(Metrics.pageW)
    private let H = Float(Metrics.pageH)
    private let tearY = Float(Metrics.tearY)

    init() {
        reset()
    }

    /// Rest layout: a flat page hanging on the pad.
    func reset() {
        pos.removeAll(keepingCapacity: true)
        var jitter = SeededRandom(seed: 0xC0FFEE)
        for r in 0..<Self.rows {
            let y = rowY(r)
            for c in 0..<Self.cols {
                let x = Float(c) / Float(Self.cols - 1) * W
                // A hair of z noise so in-plane compression buckles OUT
                // (toward the viewer) instead of fighting a perfect plane.
                pos.append(SIMD3(x, y, 0.02 + 0.02 * jitter.unit()))
            }
        }
        prev = pos
        home = pos
        fiberIntact = .init(repeating: true, count: Self.cols)
        grabIndex = nil
        sleeping = true
        if constraints.isEmpty { buildConstraints() }
    }

    private func rowY(_ r: Int) -> Float {
        switch r {
        case 0: return 0
        case 1: return tearY
        default: return tearY + (H - tearY) * Float(r - 1) / Float(Self.rows - 2)
        }
    }

    private func idx(_ r: Int, _ c: Int) -> Int { r * Self.cols + c }

    private func buildConstraints() {
        func add(_ a: Int, _ b: Int, _ k: Float) {
            constraints.append(.init(a: a, b: b, rest: simd_distance(home[a], home[b]), k: k))
        }
        for r in 0..<Self.rows {
            for c in 0..<Self.cols {
                let i = idx(r, c)
                // Structural: paper cannot stretch, full stiffness.
                if c + 1 < Self.cols { add(i, idx(r, c + 1), 1.0) }
                if r + 1 < Self.rows { add(i, idx(r + 1, c), 1.0) }
                // Shear: paper barely shears in-plane.
                if c + 1 < Self.cols, r + 1 < Self.rows {
                    add(i, idx(r + 1, c + 1), 0.9)
                    add(idx(r, c + 1), idx(r + 1, c), 0.9)
                }
                // Bending: what separates stiff paper from floppy cloth.
                if c + 2 < Self.cols { add(i, idx(r, c + 2), 0.55) }
                if r + 2 < Self.rows { add(i, idx(r + 2, c), 0.55) }
            }
        }
    }

    // MARK: Interaction

    func setGrab(at p: CGPoint) {
        var best = idx(1, 0)
        var bestD = Float.greatestFiniteMagnitude
        for r in 1..<Self.rows {
            for c in 0..<Self.cols {
                let i = idx(r, c)
                let d = simd_distance_squared(
                    SIMD3(Float(p.x), Float(p.y), 0),
                    SIMD3(home[i].x, home[i].y, 0)
                )
                if d < bestD { bestD = d; best = i }
            }
        }
        grabIndex = best
        grabTarget = SIMD3(Float(p.x), Float(p.y), 16)
        sleeping = false
    }

    func moveGrab(to p: CGPoint, lift: CGFloat) {
        grabTarget = SIMD3(Float(p.x), Float(p.y), 10 + 20 * Float(lift))
        sleeping = false
    }

    func release() {
        grabIndex = nil
        sleeping = false
    }

    /// Seam state comes from the gesture's crack model: columns within
    /// `front` of `centerX` have lost their fiber at the tear line.
    func setSeam(centerX: CGFloat, front: CGFloat) {
        for c in 0..<Self.cols {
            let x = Float(c) / Float(Self.cols - 1) * W
            let broken = abs(x - Float(centerX)) < Float(front)
            if broken, fiberIntact[c] { sleeping = false }
            fiberIntact[c] = fiberIntact[c] && !broken
        }
    }

    // MARK: Stepping

    func step(_ dt: Float) {
        guard !sleeping else { return }
        let sub = 2
        let h = min(dt, 1.0 / 30.0) / Float(sub)
        for _ in 0..<sub { substep(h) }
        checkSleep()
    }

    private func pinned(_ i: Int) -> Bool {
        let r = i / Self.cols
        if r == 0 { return true }                       // under the staples
        if r == 1 { return fiberIntact[i % Self.cols] } // seam fiber
        return i == grabIndex
    }

    private func substep(_ h: Float) {
        let h2 = h * h
        let held = grabIndex != nil
        // Held paper carries its momentum; released paper is spring-stiff —
        // bending energy snaps it flat against the pad with barely a bounce.
        let damp: Float = held ? 0.975 : 0.93
        for i in pos.indices where !pinned(i) {
            var v = (pos[i] - prev[i]) * damp
            v.z *= 0.9 // air resists the out-of-plane flap hardest
            prev[i] = pos[i]
            pos[i] += v
            pos[i].y += 480 * h2 // gravity down the wall
            pos[i].z += 40 * h2  // the pad nudges slack paper outward
            if !held {
                // Torn-free columns keep their hang; attached paper flattens.
                let k: Float = fiberIntact[i % Self.cols] ? 0.09 : 0.03
                pos[i] += (home[i] - pos[i]) * k
            }
        }
        if let g = grabIndex { pos[g] = grabTarget }

        for _ in 0..<7 {
            for con in constraints {
                let wa: Float = pinned(con.a) ? 0 : 1
                let wb: Float = pinned(con.b) ? 0 : 1
                let wSum = wa + wb
                if wSum == 0 { continue }
                let d = pos[con.b] - pos[con.a]
                let len = max(simd_length(d), 1e-5)
                let corr = d * ((len - con.rest) / len * con.k)
                pos[con.a] += corr * (wa / wSum)
                pos[con.b] -= corr * (wb / wSum)
            }
            // Pins never drift; the grip never slips.
            for c in 0..<Self.cols {
                pos[idx(0, c)] = home[idx(0, c)]
                if fiberIntact[c] { pos[idx(1, c)] = home[idx(1, c)] }
            }
            if let g = grabIndex { pos[g] = grabTarget }
        }

        // The pad is right behind the sheet.
        for i in pos.indices where pos[i].z < 0 { pos[i].z = 0 }
    }

    private func checkSleep() {
        guard grabIndex == nil else { return }
        var maxMove: Float = 0
        var maxVel: Float = 0
        for i in pos.indices {
            maxMove = max(maxMove, simd_distance_squared(pos[i], restTarget(i)))
            maxVel = max(maxVel, simd_distance_squared(pos[i], prev[i]))
        }
        if maxVel < 0.0004 {
            if fiberIntact.allSatisfy({ $0 }), maxMove < 0.4 {
                pos = home
                prev = home
            }
            sleeping = true
        }
    }

    private func restTarget(_ i: Int) -> SIMD3<Float> { home[i] }
}

// MARK: - SpriteKit rendering

@MainActor
final class PaperScene: SKScene {
    var sim: PaperSim?
    private var sprite: SKSpriteNode?
    private var sourcePositions: [vector_float2] = []
    private var lastTime: TimeInterval = 0

    override init(size: CGSize) {
        super.init(size: size)
        backgroundColor = .clear
        scaleMode = .resizeFill
        buildSourcePositions()
    }

    required init?(coder: NSCoder) { fatalError() }

    private func buildSourcePositions() {
        // Grid vertices in warp space: row-major from the BOTTOM-left, so
        // sim row r (top-down) lands at grid row (rows-1-r).
        sourcePositions = .init(repeating: .zero, count: PaperSim.rows * PaperSim.cols)
        let sim = PaperSim() // rest layout only
        for r in 0..<PaperSim.rows {
            for c in 0..<PaperSim.cols {
                let p = sim.pos[r * PaperSim.cols + c]
                let gi = (PaperSim.rows - 1 - r) * PaperSim.cols + c
                sourcePositions[gi] = vector_float2(
                    p.x / Float(Metrics.pageW),
                    1 - p.y / Float(Metrics.pageH)
                )
            }
        }
    }

    func setPageTexture(_ texture: SKTexture) {
        if sprite == nil {
            let node = SKSpriteNode(texture: texture)
            node.anchorPoint = .zero
            node.size = CGSize(width: Metrics.pageW, height: Metrics.pageH)
            node.position = CGPoint(x: Metrics.shaderPadX, y: Metrics.shaderPadBottom)
            addChild(node)
            sprite = node
        } else {
            sprite?.texture = texture
        }
    }

    override func update(_ currentTime: TimeInterval) {
        guard let sim, let sprite else { return }
        let dt = lastTime == 0 ? 1.0 / 60.0 : currentTime - lastTime
        lastTime = currentTime
        sim.step(Float(dt))

        var dest = [vector_float2](repeating: .zero, count: sourcePositions.count)
        for r in 0..<PaperSim.rows {
            for c in 0..<PaperSim.cols {
                let p = sim.pos[r * PaperSim.cols + c]
                let gi = (PaperSim.rows - 1 - r) * PaperSim.cols + c
                dest[gi] = vector_float2(
                    p.x / Float(Metrics.pageW),
                    1 - p.y / Float(Metrics.pageH)
                )
            }
        }
        sprite.warpGeometry = SKWarpGeometryGrid(
            columns: PaperSim.cols - 1,
            rows: PaperSim.rows - 1,
            sourcePositions: sourcePositions,
            destinationPositions: dest
        )
    }
}
