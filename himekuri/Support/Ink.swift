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
