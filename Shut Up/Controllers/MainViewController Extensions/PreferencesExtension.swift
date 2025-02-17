//
//  Preferences.swift
//  Shut Up
//
//  Created by Ricky Romero on 6/14/20.
//  See LICENSE.md for license information.
//

import Cocoa

extension MainViewController {
    func reflectExtensionAndPreferenceStates() {
        let prefs = Preferences.main
        if prefs.setupRun {
            enableWhitelistCheckbox.state = prefs.automaticWhitelisting ? .on : .off
            showContextMenuCheckbox.state = prefs.showInMenu ? .on : .off
            updateLastCssUpdateLabel()
        }

        respondToHelperSettingsAllowed()

        if setupAssistantWarranted {
            openSetupAssistant()
        }

        // Gate the animation behind an update timestamp.
        // This prevents multiple calls of this function from
        // snapping the animation to completion.
        if lastHelperUiUpdate < helper.lastUpdated {
            lastHelperUiUpdate = helper.lastUpdated

            NSAnimationContext.runAnimationGroup({ context in
                context.duration = 0.666
                context.allowsImplicitAnimation = true
                enableHelperGuide.alphaValue = helper.enabled ? 0.0 : 1.0
                self.view.window?.layoutIfNeeded()

                if helper.enabled {
                    var frame = view.window!.frame
                    let resizeDelta = view.window!.frame.height - CGFloat(minWinHeight)
                    frame.size = NSSize(width: winWidth, height: minWinHeight)
                    frame = frame.offsetBy(dx: 0.0, dy: resizeDelta)
                    view.window!.setFrame(frame, display: true)
                }
            }) {
                if self.helper.enabled {
                    self.enableHelperGuide.isHidden = true
                }
            }
        }
    }

    func respondToHelperSettingsAllowed() {
        let prefs = Preferences.main

        enableHelperGuide.isHidden = helper.enabled
        whitelistInfoLabel.alphaValue = helper.enabled ? 1.0 : 0.4
        enableWhitelistCheckbox.isEnabled = helper.enabled && prefs.setupRun
        showContextMenuCheckbox.isEnabled = helper.enabled && prefs.setupRun
    }

    @IBAction func whitelistSettingUpdated(_ sender: NSButton) {
        Preferences.main.automaticWhitelisting = sender.state == .on
    }

    @IBAction func menuSettingUpdated(_ sender: NSButton) {
        Preferences.main.showInMenu = sender.state == .on
    }
}

// MARK: PrefsUpdateDelegate

extension MainViewController: PrefsUpdateDelegate {
    func prefsDidUpdate() {
        reflectExtensionAndPreferenceStates()
    }
}
