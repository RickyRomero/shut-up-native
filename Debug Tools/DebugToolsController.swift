//
//  DebugToolsController.swift
//  Debug Tools
//
//  Created by Ricky Romero on 6/6/20.
//  See LICENSE.md for license information.
//

import Cocoa

class DebugToolsController: NSViewController {
    @IBOutlet var lastBuildRunField: NSTextField!
    @IBOutlet var setupCompleteForBuildField: NSTextField!
    @IBOutlet var etagField: NSTextField!
    @IBOutlet var automaticWhitelistCheckbox: NSButton!
    @IBOutlet var showInMenuCheckbox: NSButton!
    @IBOutlet var lastCssUpdateField: NSTextField!

    override func viewDidLoad() {
        super.viewDidLoad()

        NotificationCenter.default.addObserver(
            forName: NSApplication.willBecomeActiveNotification,
            object: nil,
            queue: .main,
            using: enterForeground(_:)
        )
    }

    private func enterForeground(_: Notification) {
        updatePrefsWindow()
    }

    private func updatePrefsWindow() {
        let prefs = Preferences.main

        lastBuildRunField.intValue = Int32(prefs.lastBuildRun)
        setupCompleteForBuildField.intValue = 0
        etagField.stringValue = prefs.etag
        automaticWhitelistCheckbox.state = prefs.automaticWhitelisting ? .on : .off
        showInMenuCheckbox.state = prefs.showInMenu ? .on : .off
        lastCssUpdateField.intValue = Int32(prefs.lastStylesheetUpdate.timeIntervalSince1970)
    }

    @IBAction func resetGroupPrefs(_: NSButton) {
        Preferences.main.reset()
    }

    @IBAction func showGroupContainer(_: NSButton) {
        NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: Info.containerUrl.path)
    }
}
