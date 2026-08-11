//
//  StatusItemController.swift
//  MisiCopy
//
//  Drives an optional NSStatusItem in the macOS menu bar that shows
//  copy progress and a clickable menu to bring the main window forward.
//

import AppKit
import SwiftUI

@MainActor
final class StatusItemController {
    static let shared = StatusItemController()

    private var statusItem: NSStatusItem?
    private(set) var enabled: Bool = false

    private init() {}

    func setEnabled(_ enabled: Bool) {
        self.enabled = enabled
        if enabled {
            install()
        } else {
            uninstall()
        }
    }

    private func install() {
        guard statusItem == nil else { return }
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = item.button {
            button.image = NSImage(systemSymbolName: "shippingbox.fill",
                                   accessibilityDescription: "MisiCopy")
            button.imagePosition = .imageLeading
            button.title = ""
        }
        let menu = NSMenu()
        let bringForward = NSMenuItem(title: "MisiCopy",
                                      action: #selector(focusApp),
                                      keyEquivalent: "")
        bringForward.target = self
        menu.addItem(bringForward)
        item.menu = menu
        statusItem = item
    }

    private func uninstall() {
        if let item = statusItem {
            NSStatusBar.system.removeStatusItem(item)
        }
        statusItem = nil
    }

    func update(progressPercent: Int?, isRunning: Bool, speed: String?) {
        guard enabled, let button = statusItem?.button else { return }
        if isRunning, let pct = progressPercent {
            button.title = " \(pct)%" + (speed.map { " · \($0)" } ?? "")
        } else {
            button.title = ""
        }
    }

    @objc private func focusApp() {
        NSApp.activate(ignoringOtherApps: true)
        NSApp.windows.first?.makeKeyAndOrderFront(nil)
    }
}
