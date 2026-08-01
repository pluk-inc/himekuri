//
//  AppDelegate.swift
//  himekuri
//
//  Menu-bar app hosting the floating himekuri pad.
//

import Cocoa
import Sparkle
import SwiftUI

@main
class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    static let modeKey = "himekuri.windowMode"

    private var paperWindow: PaperWindow?
    private var statusItem: NSStatusItem?

    let updaterController = SPUStandardUpdaterController(
        startingUpdater: true,
        updaterDelegate: nil,
        userDriverDelegate: nil
    )

    func applicationDidFinishLaunching(_ notification: Notification) {
        UserDefaults.standard.register(defaults: [
            Self.modeKey: WindowMode.floating.rawValue,
        ])
        NSApp.setActivationPolicy(.accessory)
        makeWindow()
        makeStatusItem()
        NSApp.activate()
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        true
    }

    // MARK: - Window

    private var currentMode: WindowMode {
        WindowMode(rawValue: UserDefaults.standard.integer(forKey: Self.modeKey)) ?? .floating
    }

    private func applyMode(_ mode: WindowMode) {
        guard let window = paperWindow else { return }
        switch mode {
        case .floating:
            window.level = .floating
            window.collectionBehavior = [.canJoinAllSpaces]
            window.orderFront(nil)
        case .normal:
            window.level = .normal
            window.collectionBehavior = [.canJoinAllSpaces]
            window.orderFront(nil)
        case .desktop:
            // Just above the desktop icons, beneath every app window; stays
            // put during Mission Control and never joins the window cycle.
            window.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.desktopIconWindow)) + 1)
            window.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]
            window.orderFront(nil)
        }
    }

    private func makeWindow() {
        let rect = NSRect(x: 0, y: 0, width: Metrics.windowW, height: Metrics.windowH)
        let window = PaperWindow(
            contentRect: rect,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = false
        // Window movement is handled by an explicit WindowDragGesture on the pad,
        // so it never steals the tear gesture.
        window.isMovableByWindowBackground = false
        window.isReleasedWhenClosed = false

        let host = PassThroughHostingView(rootView: ContentView())
        host.frame = rect
        let margin: CGFloat = 14
        host.interactiveRect = CGRect(
            x: (Metrics.windowW - Metrics.pageW) / 2 - margin,
            y: Metrics.blockTopPad - 8,
            width: Metrics.pageW + 2 * margin,
            height: Metrics.bindingH + Metrics.pageH + 44
        )
        window.contentView = host
        paperWindow = window
        applyMode(currentMode)

        if !window.setFrameUsingName("HimekuriWindow"), let screen = NSScreen.main {
            let v = screen.visibleFrame
            window.setFrameOrigin(NSPoint(
                x: v.maxX - Metrics.windowW - 36,
                y: v.maxY - Metrics.windowH + 40
            ))
        }
        window.setFrameAutosaveName("HimekuriWindow")
        window.makeKeyAndOrderFront(nil)
    }

    // MARK: - Status item

    private func makeStatusItem() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        item.button?.image = NSImage(
            systemSymbolName: "calendar",
            accessibilityDescription: "Himekuri"
        )

        let menu = NSMenu()
        menu.delegate = self

        menu.addItem(withTitle: "Show Calendar", action: #selector(showCalendar), keyEquivalent: "")
        menu.addItem(.separator())

        let themeItem = NSMenuItem(title: "Theme", action: nil, keyEquivalent: "")
        let themeMenu = NSMenu()
        themeMenu.delegate = self
        for theme in PageTheme.allCases {
            let item = NSMenuItem(title: theme.title, action: #selector(selectTheme(_:)), keyEquivalent: "")
            item.tag = 20 + theme.rawValue
            themeMenu.addItem(item)
        }
        menu.setSubmenu(themeMenu, for: themeItem)
        menu.addItem(themeItem)
        menu.addItem(.separator())

        for mode in WindowMode.allCases {
            let item = NSMenuItem(title: mode.title, action: #selector(selectMode(_:)), keyEquivalent: "")
            item.tag = 10 + mode.rawValue
            menu.addItem(item)
        }

        #if DEBUG
        // Development escape hatch only — a shipped himekuri has no way back.
        menu.addItem(.separator())
        menu.addItem(withTitle: "Reset to Today… (Dev)", action: #selector(resetToToday), keyEquivalent: "")
        #endif

        menu.addItem(.separator())
        menu.addItem(withTitle: "About Himekuri", action: #selector(showAbout), keyEquivalent: "")
        menu.addItem(withTitle: "Check for Updates…", action: #selector(checkForUpdates(_:)), keyEquivalent: "")
        menu.addItem(withTitle: "Quit Himekuri", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")

        item.menu = menu
        statusItem = item
    }

    func menuNeedsUpdate(_ menu: NSMenu) {
        let defaults = UserDefaults.standard
        for mode in WindowMode.allCases {
            menu.item(withTag: 10 + mode.rawValue)?.state = mode == currentMode ? .on : .off
        }
        let currentTheme = defaults.integer(forKey: PageTheme.defaultsKey)
        for theme in PageTheme.allCases {
            menu.item(withTag: 20 + theme.rawValue)?.state = theme.rawValue == currentTheme ? .on : .off
        }
    }

    // MARK: - Actions

    @objc private func showCalendar() {
        guard let window = paperWindow else { return }
        if let screen = NSScreen.main, !screen.visibleFrame.intersects(window.frame) {
            window.center()
        }
        window.makeKeyAndOrderFront(nil)
        NSApp.activate()
    }

    @objc private func selectMode(_ sender: NSMenuItem) {
        guard let mode = WindowMode(rawValue: sender.tag - 10) else { return }
        UserDefaults.standard.set(mode.rawValue, forKey: Self.modeKey)
        applyMode(mode)
    }

    @objc private func selectTheme(_ sender: NSMenuItem) {
        UserDefaults.standard.set(sender.tag - 20, forKey: PageTheme.defaultsKey)
    }

    @objc private func showAbout() {
        NSApp.activate()
        NSApp.orderFrontStandardAboutPanel(nil)
    }

    @IBAction func checkForUpdates(_ sender: Any?) {
        NSApp.activate()
        updaterController.updater.checkForUpdates()
    }

    #if DEBUG
    @objc private func resetToToday() {
        let alert = NSAlert()
        alert.messageText = "Reset the pad to today's page?"
        alert.informativeText = "The calendar will show today again. This is the only way back."
        alert.addButton(withTitle: "Reset")
        alert.addButton(withTitle: "Cancel")
        NSApp.activate()
        if alert.runModal() == .alertFirstButtonReturn {
            NotificationCenter.default.post(name: .himekuriResetToToday, object: nil)
        }
    }
    #endif
}
