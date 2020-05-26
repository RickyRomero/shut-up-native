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
    var blockerEnabled = true
    var helperEnabled = true
    var onboardingActive = false
    var winWidth = 800.0
    var minWinHeight = 0.0

    lazy var sheetViewController: NSViewController = {
        self.storyboard!.instantiateController(withIdentifier: "SetupModalController") as! NSViewController
    }()

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
            using: checkExtensions(_:)
        )
    }

    override func viewWillAppear() {
        super.viewWillAppear()

        // Get and store minimum window height for use in animation later
        var frame = view.window!.frame
        frame.size = NSSize(width: 0, height: 0)
        view.window!.setFrame(frame, display: true)
        view.window!.layoutIfNeeded()
        minWinHeight = Double(view.window!.frame.height)

        view.window!.center()
    }

    override func viewDidAppear() {
        super.viewDidAppear()

        whitelistScrollView.becomeFirstResponder()
    }

    func respondToExtensionStates() {
        let prefs = Preferences.main

        enableHelperGuide.isHidden = helperEnabled
        whitelistInfoLabel.alphaValue = helperEnabled ? 1.0 : 0.4
        enableWhitelistCheckbox.isEnabled = helperEnabled && prefs.setupRun
        showContextMenuCheckbox.isEnabled = helperEnabled && prefs.setupRun

        if (!blockerEnabled && !onboardingActive) {
            // Open the sheet
            presentAsSheet(sheetViewController)
            onboardingActive = true
        } else if (blockerEnabled && onboardingActive) {
            // Close the sheet
            dismiss(sheetViewController)
            onboardingActive = false
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

    func checkExtensions(_: Notification) {
        SFSafariExtensionManager.getStateOfSafariExtension(withIdentifier: Info.helperBundleId) { state, error in
            self.updateExtensionStatus(Info.helperBundleId, state?.isEnabled, error)
        }
        SFContentBlockerManager.getStateOfContentBlocker(withIdentifier: Info.blockerBundleId) { state, error in
            self.updateExtensionStatus(Info.blockerBundleId, state?.isEnabled, error)
        }
    }

    func updateExtensionStatus(_ id: String, _ state: Bool?, _ error: Error?) {
        guard error == nil else {
            DispatchQueue.main.async {
                self.presentError(MessagingError(BrowserError.requestingExtensionStatus))
            }
            return
        }

        if id == Info.blockerBundleId {
            self.blockerEnabled = state!
        } else if id == Info.helperBundleId {
            self.helperEnabled = state!
        }

        DispatchQueue.main.async { self.respondToExtensionStates() }
    }

    @IBAction func openSafariExtensionPreferences(_ sender: NSButton?) {
        SFSafariApplication.showPreferencesForExtension(withIdentifier: Info.helperBundleId) { error in
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
    }
}
