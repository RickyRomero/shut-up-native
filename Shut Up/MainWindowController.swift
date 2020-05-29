//
//  MainWindowController.swift
//  Shut Up
//
//  Created by Ricky Romero on 10/20/19.
//  Copyright © 2019 Ricky Romero. All rights reserved.
//

import Cocoa

class MainWindowController: NSWindowController {
    @IBOutlet var mainWindow: NSWindow!
    @IBOutlet var toolbar: NSToolbar!

    override func windowDidLoad() {
        super.windowDidLoad()

        shouldCascadeWindows = false
        windowFrameAutosaveName = "MainWindow"

        mainWindow.isMovableByWindowBackground = true

        if #available(macOS 10.13, *) {} else {
            // WORKAROUND: macOS Sierra has a bug where the toolbar renders
            // despite the title bar's visibility setting.
            toolbar.isVisible = false

            // After setting that, we need to work around another bug where it
            // clobbers the transparent setting we specified in the storyboard.
            mainWindow.titlebarAppearsTransparent = true

            // Now we need to clear out the title, because there doesn't seem
            // to be any other way to hide it here...
            mainWindow.title = ""
        }
    }
}
