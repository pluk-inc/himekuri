//
//  AppDelegate.swift
//  himekuri
//
//  Menu-bar app hosting the floating himekuri pad.
//

import Cocoa
import ServiceManagement
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
            Self.modeKey: WindowMode.default.rawValue,
        ])
        NSApp.setActivationPolicy(.accessory)
        makeWindow()
        makeStatusItem()
        activateApp()
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        true
    }

    /// Bring the pad forward. The cooperative `activate()` is macOS 14+;
    /// older systems only have the blunt instrument.
    private func activateApp() {
        if #available(macOS 14.0, *) {
            NSApp.activate()
        } else {
            NSApp.activate(ignoringOtherApps: true)
        }
    }

    // MARK: - Window

    private var currentMode: WindowMode {
        WindowMode(rawValue: UserDefaults.standard.integer(forKey: Self.modeKey)) ?? .default
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
        // Window movement is handled by an explicit drag handle on the pad's
        // binding, so it never steals the tear gesture.
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
            accessibilityDescription: String(localized: "Himekuri")
        )

        let menu = NSMenu()
        menu.delegate = self

        menu.addItem(withTitle: String(localized: "Show Calendar"), action: #selector(showCalendar), keyEquivalent: "")
        menu.addItem(.separator())

        let themeItem = NSMenuItem(title: String(localized: "Theme"), action: nil, keyEquivalent: "")
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
        // SMAppService is Ventura and later. Registering a login item the old
        // way needs a bundled helper, which is not worth carrying for the few
        // Monterey machines left — they just don't get the toggle, and the
        // separator goes with it so the menu doesn't gain a double rule.
        if #available(macOS 13.0, *) {
            menu.addItem(.separator())
            let login = NSMenuItem(
                title: String(localized: "Launch at Login"),
                action: #selector(toggleLaunchAtLogin),
                keyEquivalent: ""
            )
            login.tag = 3
            menu.addItem(login)
        }

        #if DEBUG
        // Development escape hatch only — a shipped himekuri has no way back.
        menu.addItem(.separator())
        menu.addItem(withTitle: "Reset to Today… (Dev)", action: #selector(resetToToday), keyEquivalent: "")
        #endif

        menu.addItem(.separator())
        menu.addItem(withTitle: String(localized: "About Himekuri"), action: #selector(showAbout), keyEquivalent: "")
        menu.addItem(withTitle: String(localized: "Check for Updates…"), action: #selector(checkForUpdates(_:)), keyEquivalent: "")
        // Routed through our own selector: macOS 26 auto-attaches a symbol
        // to items targeting the standard terminate(_:) action, which forces
        // an image column and indents the whole menu.
        menu.addItem(withTitle: String(localized: "Quit Himekuri"), action: #selector(quit), keyEquivalent: "q")

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
        if #available(macOS 13.0, *) {
            menu.item(withTag: 3)?.state = SMAppService.mainApp.status == .enabled ? .on : .off
        }
    }

    // MARK: - Actions

    /// Whether enough of `frame` lands on the displays that are actually attached.
    ///
    /// Pure and non-private so the multi-display behaviour can be exercised without a second
    /// monitor: pass synthetic `visibleFrames` rather than `NSScreen.screens`.
    ///
    /// Two things the previous `NSScreen.main.visibleFrame.intersects(_:)` check could not say.
    /// `NSScreen.main` is the screen holding keyboard focus, not the screen the pad is on, so a
    /// pad sitting happily on a second display failed the test whenever focus was elsewhere and
    /// got re-centred away from where the user left it. And `intersects` is satisfied by a single
    /// pixel, so a pad stranded 99% off-screen after a disconnect passed the test and was never
    /// recovered.
    static func isSufficientlyVisible(
        _ frame: CGRect,
        on visibleFrames: [CGRect],
        minimumFraction: CGFloat = 0.5
    ) -> Bool {
        let area = frame.width * frame.height
        guard area > 0 else { return false }

        let visible = visibleFrames.reduce(CGFloat.zero) { total, screen in
            let overlap = screen.intersection(frame)
            return overlap.isNull ? total : total + overlap.width * overlap.height
        }
        return visible >= area * minimumFraction
    }

    @objc private func showCalendar() {
        guard let window = paperWindow else { return }
        // Check every attached display, not just the focused one.
        if !Self.isSufficientlyVisible(window.frame, on: NSScreen.screens.map(\.visibleFrame)) {
            window.center()
        }
        window.makeKeyAndOrderFront(nil)
        activateApp()
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
        activateApp()
        NSApp.orderFrontStandardAboutPanel(nil)
    }

    @IBAction func checkForUpdates(_ sender: Any?) {
        activateApp()
        updaterController.updater.checkForUpdates()
    }

    @available(macOS 13.0, *)
    @objc private func toggleLaunchAtLogin() {
        // Registration can fail (e.g. parental controls); the checkmark
        // reads back the real status either way.
        if SMAppService.mainApp.status == .enabled {
            try? SMAppService.mainApp.unregister()
        } else {
            try? SMAppService.mainApp.register()
        }
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }

    #if DEBUG
    @objc private func resetToToday() {
        let alert = NSAlert()
        alert.messageText = "Reset the pad to today's page?"
        alert.informativeText = "The calendar will show today again, behind the two welcome pages. This is the only way back."
        alert.addButton(withTitle: "Reset")
        alert.addButton(withTitle: "Cancel")
        activateApp()
        if alert.runModal() == .alertFirstButtonReturn {
            NotificationCenter.default.post(name: .himekuriResetToToday, object: nil)
        }
    }
    #endif
}
