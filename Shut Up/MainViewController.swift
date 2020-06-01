//
//  ViewController.swift
//  shutup
//
//  Created by Ricky Romero on 9/2/19.
//  Copyright © 2019 Ricky Romero. All rights reserved.
//

import Cocoa
import SafariServices

class MainViewController: NSViewController {

    @IBOutlet var enableHelperGuide: NSStackView!
    @IBOutlet var enableWhitelistCheckbox: NSButton!
    @IBOutlet var whitelistInfoLabel: NSTextField!
    @IBOutlet var showContextMenuCheckbox: NSButton!
    @IBOutlet var whitelistView: NSTableView!
    @IBOutlet var whitelistScrollView: NSScrollView!

    var minWinHeight: Double!
    var winWidth = 800.0
    var blockerEnabled = true
    var helperEnabled = true
    var onboardingActive: Bool { view.window?.sheets.count ?? 0 > 0 }

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
        let sheetViewController = storyboard!.instantiateController(withIdentifier: "SetupModalController") as! NSViewController
        presentAsSheet(sheetViewController)
    }

    func respondToExtensionStates() {
        let prefs = Preferences.main

        enableHelperGuide.isHidden = helperEnabled
        whitelistInfoLabel.alphaValue = helperEnabled ? 1.0 : 0.4
        enableWhitelistCheckbox.isEnabled = helperEnabled && prefs.setupRun
        showContextMenuCheckbox.isEnabled = helperEnabled && prefs.setupRun

        if (!blockerEnabled && !onboardingActive) {
            openSetupAssistant()
        }

        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.666
            context.allowsImplicitAnimation = true
            enableHelperGuide.alphaValue = helperEnabled ? 0.0 : 1.0
            self.view.window?.layoutIfNeeded()

            if helperEnabled {
                var frame = view.window!.frame
                let resizeDelta = view.window!.frame.height - CGFloat(minWinHeight)
                frame.size = NSSize(width: winWidth, height: minWinHeight)
                frame = frame.offsetBy(dx: 0.0, dy: resizeDelta)
                view.window!.setFrame(frame, display: true)
            }
        }) {
            if self.helperEnabled {
                self.enableHelperGuide.isHidden = true
            }
        }
    }

    func appReceivedFocus(_: Notification) {
        guard Preferences.main.setupRun else { return }
        prefsDidUpdate()

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
        let prefs = Preferences.main
        enableWhitelistCheckbox.state = prefs.automaticWhitelisting ? .on : .off
        showContextMenuCheckbox.state = prefs.showInMenu ? .on : .off
        enableWhitelistCheckbox.isEnabled = helperEnabled
        showContextMenuCheckbox.isEnabled = helperEnabled

        if (!onboardingActive && prefs.needsSetupAssistant) {
            openSetupAssistant()
        }
    }
}
