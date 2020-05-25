//
//  SetupModalController.swift
//  Shut Up
//
//  Created by Ricky Romero on 10/14/19.
//  Copyright © 2019 Ricky Romero. All rights reserved.
//

import Cocoa

class SetupModalController: NSViewController {

    override func viewWillAppear() {
        print("henlo wourld")
    }

    override func performKeyEquivalent(with event: NSEvent) -> Bool {
        super.performKeyEquivalent(with: event)
        print("hi")
        dump(event)
        return true
    }
}


