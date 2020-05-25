//
//  SetupModalController.swift
//  Shut Up
//
//  Created by Ricky Romero on 10/14/19.
//  Copyright © 2019 Ricky Romero. All rights reserved.
//

import Cocoa

class SetupModalController: NSViewController {
    @IBAction func performClose(_ sender: Any) {
        view.window?.close()
        NSApp.terminate(sender)
    }

    @IBAction func terminate(_ sender: Any) {
        view.window?.close()
        NSApp.terminate(sender)
    }
}
