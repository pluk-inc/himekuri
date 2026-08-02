//
//  Snapshot.swift
//  himekuri
//
//  Printing a SwiftUI page into a bitmap the paper solver can warp.
//

import AppKit
import SwiftUI

@MainActor
enum Snapshot {
    /// Renders `view` at its natural size into a bitmap.
    ///
    /// `ImageRenderer` only exists from Ventura on, so below that the view is
    /// hosted in an offscreen window and its display cached. The legacy path
    /// renders at the main screen's backing scale rather than an arbitrary
    /// one — on Retina that is the 2× the caller asks for anyway.
    static func cgImage<V: View>(of view: V, scale: CGFloat) -> CGImage? {
        if #available(macOS 13.0, *) {
            let renderer = ImageRenderer(content: view)
            renderer.scale = scale
            return renderer.cgImage
        }
        return hostedCGImage(of: view)
    }

    private static func hostedCGImage<V: View>(of view: V) -> CGImage? {
        let host = NSHostingView(rootView: view)
        let size = host.fittingSize
        guard size.width > 0, size.height > 0 else { return nil }
        host.frame = CGRect(origin: .zero, size: size)

        // A window is what gives the hosting view a backing scale factor;
        // cached display of a detached view would come out at 1×.
        let window = NSWindow(
            contentRect: host.frame,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        window.isOpaque = false
        window.backgroundColor = .clear
        window.contentView = host
        host.layoutSubtreeIfNeeded()

        guard let rep = host.bitmapImageRepForCachingDisplay(in: host.bounds) else { return nil }
        host.cacheDisplay(in: host.bounds, to: rep)
        window.contentView = nil
        return rep.cgImage
    }
}
