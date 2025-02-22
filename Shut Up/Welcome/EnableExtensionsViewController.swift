//
//  EnableExtensionsViewController.swift
//  Shut Up
//
//  Created by Ricky Romero on 5/25/20.
//  See LICENSE.md for license information.
//

import Cocoa
import SafariServices

class EnableExtensionsViewController: NSViewController, PageContentResponder {
    @IBOutlet var coreEnableButton: NSButton!
    @IBOutlet var requiredLabel: NSTextField!
    @IBOutlet var helperEnableButton: NSButton!

    var blockerEnabled = false
    var helperEnabled = false
    var delegate: WelcomePageDelegate?

    override func viewWillAppear() {
        super.viewWillAppear()

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
            for state in states {
                guard state.error == nil else {
                    errorOccurred = true
                    continue
                }

                switch state.id {
                    case Info.blockerBundleId: self.blockerEnabled = state.state!
                    case Info.helperBundleId: self.helperEnabled = state.state!
                    default: break
                }
            }

            self.update(button: self.coreEnableButton, extEnabled: self.blockerEnabled)
            self.update(button: self.helperEnableButton, extEnabled: self.helperEnabled)

            var requiredSwatch: NSColor
            requiredSwatch = NSColor(named: "Required Swatch")!
            let labelColor = self.blockerEnabled ?
                NSColor.secondaryLabelColor :
                requiredSwatch
            self.requiredLabel.textColor = labelColor

            self.delegate?.updateContinueButton(with: self.blockerEnabled)

            if errorOccurred {
                showError(BrowserError.requestingExtensionStatus)
            }
        }
    }

    func update(button: NSButton, extEnabled: Bool) {
        if extEnabled {
            button.title = String(localized: "Enabled")
            button.image = NSImage(named: "NSMenuOnStateTemplate")
            button.isEnabled = false
        } else {
            button.title = String(localized: "Enable…")
            button.image = nil
            button.isEnabled = true
        }
    }

    @IBAction func coreButtonClicked(_ sender: NSButton) {
        BrowserBridge.main.showPrefs(for: Info.blockerBundleId) { error in
            guard error == nil else {
                showError(BrowserError.showingSafariPreferences)
                return
            }
        }
    }

    @IBAction func helperButtonClicked(_ sender: NSButton) {
        BrowserBridge.main.showPrefs(for: Info.helperBundleId) { error in
            guard error == nil else {
                showError(BrowserError.showingSafariPreferences)
                return
            }
        }
    }
}
