//
//  WindowDrag.swift
//  himekuri
//
//  Dragging the pad around the desk by its binding.
//

import AppKit
import SwiftUI

extension View {
    /// Makes this view a handle that moves the containing window.
    ///
    /// `WindowDragGesture` is macOS 15+. Older systems get an overlaid AppKit
    /// view that hands the mouse-down straight to the window — the same thing
    /// `performDrag(with:)` has always done, snapping and Spaces included.
    func windowDragHandle() -> some View {
        modifier(WindowDragHandleModifier())
    }
}

private struct WindowDragHandleModifier: ViewModifier {
    func body(content: Content) -> some View {
        if #available(macOS 15.0, *) {
            content.gesture(WindowDragGesture())
        } else {
            content.overlay(LegacyWindowDragHandle())
        }
    }
}

private struct LegacyWindowDragHandle: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView { DragView() }

    func updateNSView(_ nsView: NSView, context: Context) {}

    final class DragView: NSView {
        override func mouseDown(with event: NSEvent) {
            window?.performDrag(with: event)
        }

        /// The pad lives in an accessory-policy app that is often inactive;
        /// without this the first click would only bring it forward.
        override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }
    }
}
