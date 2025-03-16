//
//  WelcomePageController.swift
//  Shut Up
//
//  Created by Ricky Romero on 5/25/20.
//  See LICENSE.md for license information.
//

import Cocoa

class WelcomePageController: NSPageController {
    @IBOutlet var continueButton: NSButton!
    @IBOutlet var defaultBrowserButton: NSButton!

    // Store these for later so we don't get unexpected behavior
    // if the user suddenly swaps their defaults on us
    let defaultBrowser = BrowserBridge.main.defaultBrowser
    let defaultBrowserName = BrowserBridge.main.defaultBrowserName

    var currentLocation: String {
        guard let location = arrangedObjects[selectedIndex] as? String else {
            fatalError("Expected arrangedObjects item at index \(selectedIndex) to be a String")
        }
        return location
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        delegate = self
        arrangedObjects = ["EnableExtensionsVC"]
        transitionStyle = .horizontalStrip

        if Preferences.main.needsSetupAssistant {
            arrangedObjects.insert("WelcomeVC", at: 0)
        }

        defaultBrowserButton.title = String(localized: "Get for \(defaultBrowserName)")

        updateState()
    }

    func updateState() {
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.666
            context.allowsImplicitAnimation = true
            view.layoutSubtreeIfNeeded()

            switch currentLocation {
            case "WelcomeVC":
                defaultBrowserButton.isHidden = true
                continueButton.title = String(localized: "Get Started",
                                              comment: "Welcome page continue button")
                continueButton.keyEquivalent = "\r"
            case "DefaultBrowserVC":
                defaultBrowserButton.isHidden = false
                continueButton.title = String(localized: "Continue with Safari",
                                              comment: "Welcome page continue button")
                continueButton.keyEquivalent = ""
            case "EnableExtensionsVC":
                defaultBrowserButton.isHidden = true
                continueButton.title = String(localized: "Finish",
                                              comment: "Welcome page continue button")
                continueButton.isEnabled = false
                continueButton.keyEquivalent = "\r"
            default: break
            }
        }
    }

    @IBAction func continueButtonClicked(_ sender: NSButton) {
        guard currentLocation != "EnableExtensionsVC" else {
            Preferences.main.setupAssistantCompleteForBuild = Info.buildNum
            view.window?.close()
            return
        }

        if currentLocation == "WelcomeVC" {
            switch defaultBrowser {
            case .chrome, .firefox, .edge, .brave, .opera:
                arrangedObjects.insert("DefaultBrowserVC", at: 1)
            default:
                break
            }
        }

        navigateForward(sender)
        updateState()
    }

    @IBAction func defaultBrowserClicked(_: NSButton) {
        Links.collection.open(by: defaultBrowser)
    }
}

extension WelcomePageController: NSPageControllerDelegate {
    func pageController(_: NSPageController, viewControllerForIdentifier identifier: String) -> NSViewController {
        guard let pcr = NSStoryboard(
            name: "Main", bundle: nil
        ).instantiateController(
            withIdentifier: identifier
        ) as? PageContentResponder else {
            fatalError("Could not instantiate view controller with identifier \(identifier) as PageContentResponder")
        }
        pcr.delegate = self
        return pcr
    }

    func pageController(_: NSPageController, identifierFor object: Any) -> String {
        String(describing: object)
    }

    func pageControllerDidEndLiveTransition(_: NSPageController) {
        completeTransition()
    }
}

protocol PageContentResponder: NSViewController {
    var delegate: WelcomePageDelegate? { get set }
}

protocol WelcomePageDelegate {
    func updateContinueButton(with state: Bool)
}

extension WelcomePageController: WelcomePageDelegate {
    func updateContinueButton(with state: Bool) {
        continueButton.isEnabled = state
    }
}
