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

    override func viewDidLoad() {
        super.viewDidLoad()

        delegate = self
        arrangedObjects = ["WelcomeVC", "EnableExtensionsVC"]
        transitionStyle = .horizontalStrip

        defaultBrowserButton.title = "Get for \(defaultBrowserName)"
        defaultBrowserButton.isHidden = true
    }

    @IBAction func continueButtonClicked(_ sender: NSButton) {
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
    }

    @IBAction func defaultBrowserClicked(_ sender: NSButton) {
        Links.openStorePageFor(defaultBrowser)
    }
}

extension WelcomePageController: NSPageControllerDelegate {
    func pageController(_ pageController: NSPageController, viewControllerForIdentifier identifier: String) -> NSViewController {
        NSStoryboard.init(name: "Main", bundle: nil).instantiateController(withIdentifier: identifier) as! NSViewController
    }
    
    func pageController(_ pageController: NSPageController, identifierFor object: Any) -> String {
        String(describing: object)
    }
    
    func pageControllerDidEndLiveTransition(_ pageController: NSPageController) {
        completeTransition()
    }
}
