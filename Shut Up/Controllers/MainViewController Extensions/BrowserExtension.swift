//
//  BrowserExtension.swift
//  Shut Up
//
//  Created by Ricky Romero on 6/14/20.
//  See LICENSE.md for license information.
//

import Cocoa

struct Extension {
    private var _enabled: Bool?
    var enabled: Bool {
        get { _enabled ?? true }
        set {
            if newValue != _enabled {
                lastUpdated = Date()
            }
            _enabled = newValue
        }
    }

    private var _lastUpdated: Date?
    var lastUpdated: Date {
        get { _lastUpdated ?? Date(timeIntervalSince1970: 0) }
        set { _lastUpdated = newValue }
    }
}

extension MainViewController {
    @IBAction func openSafariExtensionPreferences(_: NSButton?) {
        BrowserBridge.main.showPrefs(for: Info.helperBundleId) { error in
            guard error == nil else {
                showError(BrowserError.showingSafariPreferences)
                return
            }
        }
    }
}
