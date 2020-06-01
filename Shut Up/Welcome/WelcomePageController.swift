//
//  WelcomePageController.swift
//  Shut Up
//
//  Created by Ricky Romero on 5/25/20.
//  Copyright © 2020 Ricky Romero. All rights reserved.
//

import Cocoa

class WelcomePageController: NSPageController {
    @IBOutlet weak var continueButton: NSButton!
    @IBOutlet weak var defaultBrowserButton: NSButton!

    // Store these for later so we don't get unexpected behavior
    // if the user suddenly swaps their defaults on us
    let defaultBrowser = BrowserBridge.main.defaultBrowser
    let defaultBrowserName = BrowserBridge.main.defaultBrowserName

    var currentLocation: String { arrangedObjects[selectedIndex] as! String }

    override func viewDidLoad() {
        super.viewDidLoad()

        delegate = self
        arrangedObjects = ["EnableExtensionsVC"]
        transitionStyle = .horizontalStrip

        if Preferences.main.needsSetupAssistant {
            arrangedObjects.insert("WelcomeVC", at: 0)
        }

        defaultBrowserButton.title = "Get for \(defaultBrowserName)"

        updateState()
    }

    func updateState() {
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.666
            context.allowsImplicitAnimation = true
            view.layoutSubtreeIfNeeded()

            switch currentLocation {
                case "WelcomeVC":
                    defaultBrowserButton.isHidden = true
                    continueButton.title = "Get Started"
                case "DefaultBrowserVC":
                    defaultBrowserButton.isHidden = false
                    continueButton.title = "Continue with Safari"
                case "EnableExtensionsVC":
                    defaultBrowserButton.isHidden = true
                    continueButton.title = "Finish"
                    continueButton.isEnabled = false
                default: break
            }
        })
    }

    @IBAction func continueButtonClicked(_ sender: NSButton) {
        guard currentLocation != "EnableExtensionsVC" else {
            Preferences.main.setupAssistantCompleteForBuild = Info.buildNum
            self.view.window?.close()
            return
        }
        if selectedIndex == 0 {
            switch defaultBrowser {
                case .chrome: fallthrough
                case .firefox: fallthrough
                case .edge: fallthrough
                case .opera:
                    arrangedObjects.insert("DefaultBrowserVC", at: 1)
                default:
                    break
            }
        }

        navigateForward(sender)
        updateState()
    }

    @IBAction func defaultBrowserClicked(_ sender: NSButton) {
        Links.openStorePageFor(defaultBrowser)
    }
}

extension WelcomePageController: NSPageControllerDelegate {
    func pageController(_ pageController: NSPageController, viewControllerForIdentifier identifier: String) -> NSViewController {
        let pcr = NSStoryboard.init(
            name: "Main", bundle: nil
        ).instantiateController(
            withIdentifier: identifier
        ) as! PageContentResponder
        pcr.delegate = self
        return pcr as NSViewController
    }
    
    func pageController(_ pageController: NSPageController, identifierFor object: Any) -> String {
        String(describing: object)
    }
    
    func pageControllerDidEndLiveTransition(_ pageController: NSPageController) {
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
