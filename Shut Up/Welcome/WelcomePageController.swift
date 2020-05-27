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
    
    override func viewDidLoad() {
        super.viewDidLoad()

        delegate = self
        arrangedObjects = ["WelcomeVC", "EnableExtensionsVC"]
        transitionStyle = .horizontalStrip

        let defaultBrowserName = BrowserBridge.main.defaultBrowserName
        defaultBrowserButton.title = "Get for \(defaultBrowserName)"
    }

    @IBAction func continueButtonClicked(_ sender: NSButton) {
        if selectedIndex == 0 {
            switch BrowserBridge.main.defaultBrowser {
                case .unknown: fallthrough
                case .safari:
                    break

                case .chrome: fallthrough
                case .firefox: fallthrough
                case .edge: fallthrough
                case .opera:
                    arrangedObjects.insert("DefaultBrowserVC", at: 1)
            }
        }

        navigateForward(sender)
    }

    @IBAction func defaultBrowserClicked(_ sender: NSButton) {
        
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
        self.completeTransition()
    }
}
