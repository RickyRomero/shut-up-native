//
//  EnableExtensionsViewController.swift
//  Shut Up
//
//  Created by Ricky Romero on 5/25/20.
//  Copyright © 2020 Ricky Romero. All rights reserved.
//

import Cocoa
import SafariServices

class EnableExtensionsViewController: NSViewController {
    @IBOutlet var coreEnableButton: NSButton!
    @IBOutlet var helperEnableButton: NSButton!

    var blockerEnabled = false
    var helperEnabled = false

    override func viewDidLoad() {
        super.viewDidLoad()

        NotificationCenter.default.addObserver(
            forName: NSApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main,
            using: checkExtensions(_:)
        )

        checkExtensions(nil)
    }

    func checkExtensions(_: Notification?) {
        BrowserBridge.main.requestExtensionStates { states in
            var errorOccurred = false
            states.forEach { state in
                guard state.error == nil else {
                    errorOccurred = true
                    return
                }

                switch state.id {
                    case Info.blockerBundleId: self.blockerEnabled = state.state!
                    case Info.helperBundleId: self.helperEnabled = state.state!
                    default: break
                }
            }

            self.update(button: self.coreEnableButton, extEnabled: self.blockerEnabled)
            self.update(button: self.helperEnableButton, extEnabled: self.helperEnabled)
            if errorOccurred {
                self.presentError(MessagingError(BrowserError.requestingExtensionStatus))
            }
        }
    }

    func update(button: NSButton, extEnabled: Bool) {
        if extEnabled {
            button.title = "Enabled"
            button.image = NSImage(named: "NSMenuOnStateTemplate")
            button.isEnabled = false
        } else {
            button.title = "Enable…"
            button.image = nil
            button.isEnabled = true
        }
    }

    @IBAction func coreButtonClicked(_ sender: NSButton) {
        BrowserBridge.main.showPrefs(for: Info.blockerBundleId) { error in
            guard error == nil else {
                self.presentError(MessagingError(BrowserError.showingSafariPreferences))
                return
            }
        }
    }

    @IBAction func helperButtonClicked(_ sender: NSButton) {
        BrowserBridge.main.showPrefs(for: Info.helperBundleId) { error in
            guard error == nil else {
                self.presentError(MessagingError(BrowserError.showingSafariPreferences))
                return
            }
        }
    }
}
