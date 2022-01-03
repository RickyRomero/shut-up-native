//
//  SetupModalController.swift
//  Shut Up
//
//  Created by Ricky Romero on 10/14/19.
//  See LICENSE.md for license information.
//

import Cocoa

class SetupModalController: NSViewController {
    override var acceptsFirstResponder: Bool { true }

    override func viewWillAppear() {
        super.viewWillAppear()
        view.window?.styleMask.remove(.resizable)
        view.window?.preventsApplicationTerminationWhenModal = false
        view.window?.makeFirstResponder(view)
    }

    @IBAction func performClose(_ sender: Any) {
        view.window?.close()
        NSApp.terminate(sender)
    }

    @IBAction func terminate(_ sender: Any) {
        view.window?.close()
        NSApp.terminate(sender)
    }
}
