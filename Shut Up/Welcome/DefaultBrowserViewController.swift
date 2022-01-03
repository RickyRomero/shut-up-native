//
//  DefaultBrowserViewController.swift
//  Shut Up
//
//  Created by Ricky Romero on 5/26/20.
//  See LICENSE.md for license information.
//

import Cocoa

class DefaultBrowserViewController: NSViewController, PageContentResponder {
    @IBOutlet var browserIcon: NSImageView!
    @IBOutlet var heading: NSTextField!
    var delegate: WelcomePageDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()

        let defaultBrowser = BrowserBridge.main.defaultBrowserName

        let prompt = "Your default browser is \(defaultBrowser). Do you want to get the \(defaultBrowser) version of Shut Up?"

        heading.stringValue = prompt
        browserIcon.image = NSImage(named: "Large \(defaultBrowser)")
    }
    
}
