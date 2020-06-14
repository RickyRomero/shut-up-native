//
//  ViewController.swift
//  shutup
//
//  Created by Ricky Romero on 9/2/19.
//  Copyright © 2019 Ricky Romero. All rights reserved.
//

import Cocoa
import SafariServices

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

class MainViewController: NSViewController {

    @IBOutlet var enableHelperGuide: NSStackView!
    @IBOutlet var enableWhitelistCheckbox: NSButton!
    @IBOutlet var whitelistInfoLabel: NSTextField!
    @IBOutlet var showContextMenuCheckbox: NSButton!
    @IBOutlet var whitelistView: NSTableView!
    @IBOutlet var whitelistScrollView: NSScrollView!
    @IBOutlet var whitelistAddField: NSTextField!
    @IBOutlet var lastCssUpdateLabel: NSTextField!
    
    var minWinHeight: Double!
    var winWidth = 800.0

    var blocker = Extension()
    var helper = Extension()
    var lastHelperUiUpdate = Date(timeIntervalSince1970: 0)
    var cssLabelUpdateTimer: Timer?

    var onboardingActive: Bool { view.window?.sheets.count ?? 0 > 0 }
    var setupAssistantWarranted: Bool {
        let prefs = Preferences.main
        let prefsRequireAssistant = (prefs.setupRun && prefs.needsSetupAssistant)

        let blockerIsDisabled = !blocker.enabled

        return blockerIsDisabled || prefsRequireAssistant
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        Preferences.main.delegate = self
        whitelistView.delegate = self
        whitelistView.dataSource = self
        whitelistAddField.delegate = self
        enableHelperGuide.isHidden = true

        // Set up CSS update label
        let tabularFigures = NSFont.systemFont(ofSize: 0.0).fontDescriptor.addingAttributes([
            .featureSettings: [[
                NSFontDescriptor.FeatureKey.typeIdentifier: kNumberSpacingType,
                NSFontDescriptor.FeatureKey.selectorIdentifier: kMonospacedNumbersSelector
            ]]
        ])
        lastCssUpdateLabel.font = NSFont(descriptor: tabularFigures, size: 0.0)
        resetCssLabelUpdateTimer()

        // Listen for when the app receives focus
        NotificationCenter.default.addObserver(
            forName: NSApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main,
            using: appReceivedFocus(_:)
        )
    }

    override func viewWillAppear() {
        super.viewWillAppear()

        // Get and store minimum window height for use in animation later
        // Only calculate this once - otherwise the sheet gets screwed up
        guard minWinHeight == nil else { return }
        let savedFrame = view.window!.frame
        var checkFrame = savedFrame
        checkFrame.size = NSSize(width: 0, height: 0)
        view.window!.setFrame(checkFrame, display: true)
        view.window!.layoutIfNeeded()
        minWinHeight = Double(view.window!.frame.height)

        view.window!.setFrame(savedFrame, display: true)
    }

    override func viewDidAppear() {
        super.viewDidAppear()

        whitelistScrollView.becomeFirstResponder()
    }

    func openSetupAssistant() {
        guard Preferences.main.setupRun else { return }
        guard !onboardingActive else { return }

        let sheetViewController = storyboard!.instantiateController(withIdentifier: "SetupModalController") as! NSViewController
        presentAsSheet(sheetViewController)
    }

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
            print(#function, lastHelperUiUpdate.timeIntervalSince1970)
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

    func resetCssLabelUpdateTimer() {
        cssLabelUpdateTimer?.invalidate()
        cssLabelUpdateTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            DispatchQueue.main.async {
                self.updateLastCssUpdateLabel()
            }
        }
    }

    func updateLastCssUpdateLabel() {
        let timestamp = Preferences.main.lastStylesheetUpdate
        updateLastCssUpdateLabel(with: timestamp)
    }

    func updateLastCssUpdateLabel(with timestamp: Date) {
        let cutoff: Double = 60 * 60 * 24 * 7
        let cutoffDate = Date(timeIntervalSinceNow: cutoff * -1.0)
        let relativeTimeStr: String!

        if timestamp < cutoffDate {
            relativeTimeStr = "Updated over 1 week ago"
        } else {
            relativeTimeStr = "Updated \(timestamp.relativeTime)"
        }

        lastCssUpdateLabel.stringValue = relativeTimeStr
    }

    @IBAction func openSafariExtensionPreferences(_ sender: NSButton?) {
        BrowserBridge.main.showPrefs(for: Info.helperBundleId) { error in
            guard error == nil else {
                self.presentError(MessagingError(BrowserError.showingSafariPreferences))
                return
            }
        }
    }

    @IBAction func forceStylesheetUpdate(_ sender: NSButton) {
        print("Should be fetching now")
        Stylesheet.main.update(force: false) { error in
            guard error == nil else { return /* and display the error */ }
            let now = Date()
            Preferences.main.lastStylesheetUpdate = now
            self.updateLastCssUpdateLabel(with: now)
            self.resetCssLabelUpdateTimer()
        }
    }

    @IBAction func whitelistSettingUpdated(_ sender: NSButton) {
        Preferences.main.automaticWhitelisting = sender.state == .on
    }
    
    @IBAction func menuSettingUpdated(_ sender: NSButton) {
        Preferences.main.showInMenu = sender.state == .on
    }

    @IBAction func addAction(_ sender: NSTextField) {
        print(#function)
        print("action")
    }
}

// MARK: NSTableViewDataSource

extension MainViewController: NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        return 40
    }
}

// MARK: NSTableViewDelegate

extension MainViewController: NSTableViewDelegate {
    func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
        return "Hello table!"
    }

    // Swipe actions for the table view
    func tableView(_ tableView: NSTableView, rowActionsForRow row: Int, edge: NSTableView.RowActionEdge) -> [NSTableViewRowAction] {
        if (edge == .leading) {
            let saveAction = NSTableViewRowAction(style: .regular, title: "Permanent", handler: { rowAction, row in
                print("Saving...")
            })
            saveAction.backgroundColor = .cyan
            return [saveAction]
        } else if (edge == .trailing) {
            let deleteAction = NSTableViewRowAction(style: .destructive, title: "Delete", handler: { rowAction, row in
                print("Deleting...")
                self.whitelistView.removeRows(at: IndexSet(integer: row), withAnimation: .effectFade)
            })
            deleteAction.backgroundColor = .red
            return [deleteAction]
        }
        return []
    }

    func tableView(_ tableView: NSTableView, didRemove rowView: NSTableRowView, forRow row: Int) {
        print("Hey. We're removing a row. It's row \(row).")
    }
}

// MARK: PrefsUpdateDelegate

extension MainViewController: PrefsUpdateDelegate {
    func prefsDidUpdate() {
        reflectExtensionAndPreferenceStates()
    }
}

// MARK: NSTextFieldDelegate

extension MainViewController: NSTextFieldDelegate {
    func controlTextDidBeginEditing(_ obj: Notification) {
        print(#function)
    }
    func controlTextDidEndEditing(_ obj: Notification) {
        print(#function)
    }
}
