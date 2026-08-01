//
//  VerticalText.swift
//  himekuri
//
//  Tategaki: one character per line, top to bottom.
//

import SwiftUI

struct VerticalText: View {
    let text: String
    let font: Font
    var color: Color = Ink.black
    var spacing: CGFloat = 0

    init(_ text: String, font: Font, color: Color = Ink.black, spacing: CGFloat = 0) {
        self.text = text
        self.font = font
        self.color = color
        self.spacing = spacing
    }

    var body: some View {
        VStack(spacing: spacing) {
            ForEach(Array(text.enumerated()), id: \.offset) { _, ch in
                Text(String(ch)).font(font)
            }
        }
        .foregroundStyle(color)
    }
}
