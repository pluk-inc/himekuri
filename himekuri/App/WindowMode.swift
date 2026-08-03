//
//  WindowMode.swift
//  himekuri
//

import Foundation

/// Where the pad lives relative to other windows.
enum WindowMode: Int, CaseIterable {
    case floating = 0  // above everything
    case normal = 1    // an ordinary window
    case desktop = 2   // pinned to the desktop, beneath all windows

    /// Where a fresh install starts: on the desktop, like a real paper pad.
    static let `default` = WindowMode.desktop

    var title: String {
        switch self {
        case .floating: String(localized: "Float Above Windows")
        case .normal: String(localized: "Standard Window")
        case .desktop: String(localized: "Pin to Desktop")
        }
    }
}
