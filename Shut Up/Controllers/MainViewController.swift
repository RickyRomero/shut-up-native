//
//  ViewController.swift
//  shutup
//
//  Created by Ricky Romero on 9/2/19.
//  Copyright © 2019 Ricky Romero. All rights reserved.
//

import Cocoa

class MainViewController: NSViewController {
    @IBOutlet var enableHelperGuide: NSStackView!
    @IBOutlet var enableWhitelistCheckbox: NSButton!
    @IBOutlet var whitelistInfoLabel: NSTextField!
    @IBOutlet var showContextMenuCheckbox: NSButton!
    @IBOutlet var whitelistView: NSTableView!
    @IBOutlet var whitelistScrollView: NSScrollView!
    @IBOutlet var whitelistAddField: NSTextField!
    @IBOutlet var lastCssUpdateLabel: NSTextField!
    @IBOutlet var updatingIndicator: NSStackView!
    @IBOutlet var updatingSpinner: NSProgressIndicator!
    
    var minWinHeight: Double!
    var winWidth = 700.0

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

        // Piggyback off of this one-time event to also start listening for
        // when the app receives focus
        NotificationCenter.default.addObserver(
            forName: NSApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main,
            using: appReceivedFocus(_:)
        )
    }

    override func viewDidAppear() {
        super.viewDidAppear()

        whitelistScrollView.becomeFirstResponder()
    }

    func openSetupAssistant() {
        guard Preferences.main.setupRun else { return }
        guard !onboardingActive else { return }

        let windowIsVisible = view.window?.isVisible ?? false
        guard windowIsVisible else { return }

        let sheetViewController = storyboard!.instantiateController(withIdentifier: "SetupModalController") as! NSViewController
        presentAsSheet(sheetViewController)
    }
}
