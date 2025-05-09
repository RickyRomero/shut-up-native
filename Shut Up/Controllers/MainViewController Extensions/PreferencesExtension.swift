//
//  PreferencesExtension.swift
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
            }, completionHandler: {
                if self.helper.enabled {
                    self.enableHelperGuide.isHidden = true
                }
            })
        }
    }

    func respondToHelperSettingsAllowed() {
        let prefs = Preferences.main

        enableHelperGuide.isHidden = helper.enabled
        if helper.enabled, !prefs.automaticWhitelisting {
            whitelistInfoLabel.isHidden = true
        } else if !helper.enabled {
            whitelistInfoLabel.alphaValue = 0.4
        }
        enableWhitelistCheckbox.isEnabled = helper.enabled && prefs.setupRun
        showContextMenuCheckbox.isEnabled = helper.enabled && prefs.setupRun
    }

    @IBAction func whitelistSettingUpdated(_ sender: NSButton) {
        Preferences.main.automaticWhitelisting = sender.state == .on

        // If we're showing the label, unhide it first so the animation can be visible.
        if sender.state == .on {
            whitelistInfoLabel.isHidden = false
        }

        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.2
            context.allowsImplicitAnimation = true
            context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)

            // Animate the alpha value
            self.whitelistInfoLabel.alphaValue = sender.state == .on ? 1.0 : 0.0

            // Animate the height constraint from its stored full height to 0 (or vice versa)
            if let constraint = self.whitelistInfoLabel.constraints.first(where: { $0.firstAttribute == .height }) {
                constraint.constant = sender.state == .on ? self.whitelistInfoLabelHeight : 0
            }

            // Update the layout smoothly
            self.view.layoutSubtreeIfNeeded()
        }, completionHandler: {
            // Only hide the label after the animation completes when hiding
            if sender.state == .off {
                self.whitelistInfoLabel.isHidden = true
            }
        })
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
