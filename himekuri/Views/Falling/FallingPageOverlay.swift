//
//  FallingPageOverlay.swift
//  himekuri
//
//  A torn page falls in its own transparent, click-through window that spans
//  from the pad down to the bottom edge of the screen, so it drifts past
//  everything and slips off the display instead of being clipped or faded.
//

import AppKit
import SwiftUI

@MainActor
enum FallingPageOverlay {
    /// Horizontal breathing room for the flutter swings plus a thrown carry.
    private static let margin: CGFloat = 300

    static func spawn(_ piece: FallingPage) {
        guard let main = NSApp.windows.first(where: { $0 is PaperWindow }),
              let screen = main.screen ?? NSScreen.main else { return }

        let top = main.frame.maxY
        let bottom = screen.frame.minY
        // A piece flung upward needs air above the pad before it falls.
        let headroom: CGFloat = piece.upward ? min(300, max(screen.visibleFrame.maxY - top, 0)) : 0
        let height = top + headroom - bottom
        guard height > 100 else { return }

        let frame = NSRect(
            x: main.frame.minX - margin,
            y: bottom,
            width: Metrics.windowW + 2 * margin,
            height: height
        )

        let window = NSWindow(
            contentRect: frame,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = false
        window.ignoresMouseEvents = true
        window.isReleasedWhenClosed = false
        window.level = main.level
        window.collectionBehavior = main.collectionBehavior

        // Distance from the page's resting spot to fully past the screen bottom.
        let distance = (top - bottom) - Metrics.blockTopPad - Metrics.pageTopInset + 60
        let host = NSHostingView(
            rootView: FallingPageView(page: piece, fallDistance: distance, headroom: headroom)
        )
        host.frame = NSRect(origin: .zero, size: frame.size)
        window.contentView = host

        main.addChildWindow(window, ordered: .above)
        window.orderFront(nil)

        Task {
            try? await Task.sleep(nanoseconds: 3_400_000_000)
            main.removeChildWindow(window)
            window.orderOut(nil)
            window.contentView = nil
        }
    }
}
