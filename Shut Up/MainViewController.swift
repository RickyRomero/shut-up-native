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

    var minWinHeight: Double!
    var winWidth = 800.0

    var blocker = Extension()
    var helper = Extension()
    var lastHelperUiUpdate = Date(timeIntervalSince1970: 0)

    var onboardingActive: Bool { view.window?.sheets.count ?? 0 > 0 }
    var setupAssistantWarranted: Bool {
        let prefs = Preferences.main
        let prefsRequireAssistant = (prefs.setupRun && prefs.needsSetupAssistant)

        let blockerIsDisabled = !blocker.enabled

        print(#function, blockerIsDisabled, prefsRequireAssistant)
        return blockerIsDisabled || prefsRequireAssistant
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        Preferences.main.delegate = self
        whitelistView.delegate = self
        whitelistView.dataSource = self
        enableHelperGuide.isHidden = true

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

    func respondToExtensionStates() {
        print(#function)
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

            self.respondToExtensionStates()
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

    @IBAction func forceStylesheetUpdate(_ sender: NSButton) {
        print("Should be fetching now")
        Stylesheet.main.update(force: false) { error in
            print("done")
        }
    }

    @IBAction func whitelistSettingUpdated(_ sender: NSButton) {
        Preferences.main.automaticWhitelisting = sender.state == .on
    }
    
    @IBAction func menuSettingUpdated(_ sender: NSButton) {
        Preferences.main.showInMenu = sender.state == .on
    }
}

// MARK: NSTableViewDataSource

extension MainViewController: NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        return 40 // 0
    }
}

// MARK: NSTableViewDelegate

extension MainViewController: NSTableViewDelegate {
    // Return views for each table column (which is just one)
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        if let cell = whitelistView.makeView(
            withIdentifier: NSUserInterfaceItemIdentifier(
                rawValue: "WhitelistedDomain"
            ), owner: nil
        ) as? NSTableCellView {
            cell.textField?.stringValue = "What did you say about me you little bitch? I'll have you know"
            return cell
        }
        return nil
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
        respondToExtensionStates()
    }
}
