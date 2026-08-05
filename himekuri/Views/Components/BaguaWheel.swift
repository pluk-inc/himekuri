//
//  BaguaWheel.swift
//  himekuri
//
//  The 八卦 wheel stamped in the middle of an old almanac page: taiji at the
//  centre, the eight trigrams ringed around it in the Later Heaven order.
//  Drawn rather than set in type — the trigram characters are a font lottery,
//  and three bars in a ring are three bars in a ring.
//

import SwiftUI

struct BaguaWheel: View {
    let color: Color
    var size: CGFloat = 56

    /// Later Heaven (後天) order, clockwise from the top: 離 south, 坤, 兌,
    /// 乾, 坎 north, 艮, 震, 巽. Each trigram is read bottom line first, so
    /// index 0 of the triple is the line nearest the centre.
    private static let trigrams: [[Bool]] = [
        [true, false, true],   // 離 ☲
        [false, false, false], // 坤 ☷
        [true, true, false],   // 兌 ☱
        [true, true, true],    // 乾 ☰
        [false, true, false],  // 坎 ☵
        [false, false, true],  // 艮 ☶
        [true, false, false],  // 震 ☳
        [false, true, true],   // 巽 ☴
    ]

    var body: some View {
        Canvas { ctx, canvas in
            let c = CGPoint(x: canvas.width / 2, y: canvas.height / 2)
            let outer = min(canvas.width, canvas.height) / 2
            let taijiR = outer * 0.34

            drawTrigrams(&ctx, center: c, outer: outer)
            drawTaiji(&ctx, center: c, radius: taijiR)
        }
        .frame(width: size, height: size)
    }

    // MARK: - Taiji

    /// The yin half as one closed path: down the right side, back up through
    /// the two half-circles that make the S.
    private func drawTaiji(_ ctx: inout GraphicsContext, center c: CGPoint, radius r: CGFloat) {
        let disc = Path(ellipseIn: CGRect(x: c.x - r, y: c.y - r, width: r * 2, height: r * 2))

        var s = Path()
        s.move(to: CGPoint(x: c.x, y: c.y - r))
        s.addArc(center: c, radius: r,
                 startAngle: .degrees(-90), endAngle: .degrees(90), clockwise: false)
        s.addArc(center: CGPoint(x: c.x, y: c.y + r / 2), radius: r / 2,
                 startAngle: .degrees(90), endAngle: .degrees(-90), clockwise: true)
        s.addArc(center: CGPoint(x: c.x, y: c.y - r / 2), radius: r / 2,
                 startAngle: .degrees(90), endAngle: .degrees(-90), clockwise: false)
        s.closeSubpath()

        ctx.fill(s, with: .color(color))
        ctx.stroke(disc, with: .color(color), lineWidth: 0.8)

        // The eye in each half, each the reverse of its ground.
        let eye = r * 0.16
        ctx.fill(Path(ellipseIn: CGRect(x: c.x - eye, y: c.y - r / 2 - eye,
                                        width: eye * 2, height: eye * 2)),
                 with: .color(color))
        ctx.blendMode = .destinationOut
        ctx.fill(Path(ellipseIn: CGRect(x: c.x - eye, y: c.y + r / 2 - eye,
                                        width: eye * 2, height: eye * 2)),
                 with: .color(.black))
        ctx.blendMode = .normal
    }

    // MARK: - Trigrams

    private func drawTrigrams(_ ctx: inout GraphicsContext, center c: CGPoint, outer: CGFloat) {
        let barLength = outer * 0.46
        let thickness = max(outer * 0.075, 1.1)
        let gap = thickness * 1.55          // between the three lines
        let split = barLength * 0.22        // the break in a yin line
        let innerEdge = outer * 0.46        // where the first line sits

        for (i, trigram) in Self.trigrams.enumerated() {
            let angle = Double(i) / 8 * 2 * .pi
            ctx.drawLayer { layer in
                layer.translateBy(x: c.x, y: c.y)
                layer.rotate(by: .radians(angle))
                for (line, solid) in trigram.enumerated() {
                    // Rotation puts "up" at -y; lines run out from the centre.
                    let y = -(innerEdge + CGFloat(line) * gap)
                    if solid {
                        layer.fill(bar(x: -barLength / 2, y: y,
                                       w: barLength, h: thickness), with: .color(color))
                    } else {
                        let half = (barLength - split) / 2
                        layer.fill(bar(x: -barLength / 2, y: y,
                                       w: half, h: thickness), with: .color(color))
                        layer.fill(bar(x: split / 2, y: y,
                                       w: half, h: thickness), with: .color(color))
                    }
                }
            }
        }
    }

    private func bar(x: CGFloat, y: CGFloat, w: CGFloat, h: CGFloat) -> Path {
        Path(CGRect(x: x, y: y - h / 2, width: w, height: h))
    }
}
