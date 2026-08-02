//
//  Ink.swift
//  himekuri
//
//  Print palette and typography shared across page layouts.
//

import SwiftUI

enum Ink {
    static let black = Color(red: 0.10, green: 0.09, blue: 0.10)
    static let vermilion = Color(red: 0.82, green: 0.22, blue: 0.13)
    static let grain = Color(red: 0.45, green: 0.38, blue: 0.28)
}

extension Color {
    /// Blend towards `other`. `Color.mix(with:by:)` arrived in macOS 15, so
    /// older systems interpolate in sRGB instead — on the near-neutral paper
    /// tones this is used for, the two ramps are all but indistinguishable.
    func blended(with other: Color, by fraction: Double) -> Color {
        if #available(macOS 15.0, *) {
            return mix(with: other, by: fraction)
        }
        let t = min(max(fraction, 0), 1)
        guard let a = NSColor(self).usingColorSpace(.sRGB),
              let b = NSColor(other).usingColorSpace(.sRGB) else { return self }
        return Color(
            red: Double(a.redComponent + (b.redComponent - a.redComponent) * t),
            green: Double(a.greenComponent + (b.greenComponent - a.greenComponent) * t),
            blue: Double(a.blueComponent + (b.blueComponent - a.blueComponent) * t),
            opacity: Double(a.alphaComponent + (b.alphaComponent - a.alphaComponent) * t)
        )
    }
}

enum Theme {
    /// Heavy gothic for kanji (Hiragino Sans falls back to system if missing).
    static func kanji(_ size: CGFloat) -> Font {
        .custom("HiraginoSans-W7", size: size)
    }

    /// Mincho (serif) for smaller traditional text.
    static func mincho(_ size: CGFloat) -> Font {
        .custom("HiraMinProN-W6", size: size)
    }

    /// Fat slab numeral for the big day number.
    static func numeral(_ size: CGFloat) -> Font {
        .system(size: size, weight: .black, design: .serif)
    }
}
