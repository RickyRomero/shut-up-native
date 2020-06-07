//
//  DebugToolsController.swift
//  Debug Tools
//
//  Created by Ricky Romero on 6/6/20.
//  Copyright © 2020 Ricky Romero. All rights reserved.
//

import Cocoa

class DebugToolsController: NSViewController {

    @IBOutlet weak var lastBuildRunField: NSTextField!
    @IBOutlet weak var setupCompleteForBuildField: NSTextField!
    @IBOutlet weak var etagField: NSTextField!
    @IBOutlet weak var automaticWhitelistCheckbox: NSButton!
    @IBOutlet weak var showInMenuCheckbox: NSButton!
    @IBOutlet weak var lastCssUpdateField: NSTextField!

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
}
