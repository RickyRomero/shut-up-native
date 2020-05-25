//
//  WelcomePageController.swift
//  Shut Up
//
//  Created by Ricky Romero on 5/25/20.
//  Copyright © 2020 Ricky Romero. All rights reserved.
//

import Cocoa

class WelcomePageController: NSPageController {
    override func viewDidLoad() {
        super.viewDidLoad()

        delegate = self
        arrangedObjects = ["WelcomeVC", "EnableExtensionsVC"]
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
