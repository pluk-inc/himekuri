//
//  MoonPhaseDisc.swift
//  himekuri
//
//  Tonight's moon, drawn the way a one-colour press would manage it: ink where
//  the moon is lit, bare paper where it isn't. A new moon is an empty ring, a
//  full moon a solid disc.
//

import SwiftUI

struct MoonPhaseDisc: View {
    /// Lit fraction of the disc, 0…1.
    let illumination: Double
    /// Lit edge sits on the right while waxing (northern hemisphere).
    let isWaxing: Bool
    let color: Color
    var size: CGFloat = 20

    var body: some View {
        Canvas { ctx, canvas in
            let rect = CGRect(origin: .zero, size: canvas)
            let disc = Path(ellipseIn: rect)
            let k = min(max(illumination, 0), 1)

            // The terminator is a circle seen edge-on: an ellipse whose
            // semi-width shrinks to nothing at the quarters.
            let halfWidth = canvas.width / 2 * abs(1 - 2 * k)
            let terminator = Path(ellipseIn: CGRect(
                x: rect.midX - halfWidth, y: rect.minY,
                width: halfWidth * 2, height: rect.height
            ))

            // The lit half, before the terminator carves or extends it.
            let litHalf = Path(CGRect(
                x: isWaxing ? rect.midX : rect.minX, y: rect.minY,
                width: rect.width / 2, height: rect.height
            ))

            ctx.drawLayer { layer in
                layer.clip(to: disc)
                if k > 0.5 {
                    // Gibbous: the lit half plus the bulge across the middle.
                    layer.fill(litHalf, with: .color(color))
                    layer.fill(terminator, with: .color(color))
                } else {
                    // Crescent: the lit half with the bulge taken back out.
                    layer.clip(to: terminator, options: .inverse)
                    layer.fill(litHalf, with: .color(color))
                }
            }

            ctx.stroke(disc.strokedPath(.init(lineWidth: 0.7)), with: .color(color.opacity(0.9)))
        }
        .frame(width: size, height: size)
    }
}
