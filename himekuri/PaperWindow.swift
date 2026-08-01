//
//  PaperWindow.swift
//  himekuri
//
//  A borderless, transparent window that behaves like an object on the desk:
//  clicks outside the pad fall through to whatever is underneath.
//

import AppKit
import SwiftUI

final class PaperWindow: NSWindow {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}

final class PassThroughHostingView: NSHostingView<ContentView> {
    /// Region (top-left origin coordinates) that accepts mouse events.
    var interactiveRect: CGRect = .zero

    required init(rootView: ContentView) {
        super.init(rootView: rootView)
    }

    @objc required dynamic init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func hitTest(_ point: NSPoint) -> NSView? {
        let p = convert(point, from: superview)
        let topLeft = isFlipped ? p : NSPoint(x: p.x, y: bounds.height - p.y)
        guard interactiveRect.contains(topLeft) else { return nil }
        return super.hitTest(point)
    }

    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }
}
