//
//  Browser.swift
//  Shut Up
//
//  Created by Ricky Romero on 6/14/20.
//  Copyright © 2020 Ricky Romero. All rights reserved.
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
    func appReceivedFocus(_: Notification) {
        BrowserBridge.main.requestExtensionStates { states in
            var errorOccurred = false
            states.forEach { state in
                guard state.error == nil else {
                    errorOccurred = true
                    return
                }

                switch state.id {
                case Info.blockerBundleId: self.blocker.enabled = state.state!
                    case Info.helperBundleId: self.helper.enabled = state.state!
                    default: break
                }
            }

            self.reflectExtensionAndPreferenceStates()
            if errorOccurred {
                self.presentError(MessagingError(BrowserError.requestingExtensionStatus))
            }
        }
    }

    @IBAction func openSafariExtensionPreferences(_ sender: NSButton?) {
        BrowserBridge.main.showPrefs(for: Info.helperBundleId) { error in
            guard error == nil else {
                self.presentError(MessagingError(BrowserError.showingSafariPreferences))
                return
            }
        }
    }
}
