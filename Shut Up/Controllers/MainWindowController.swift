//
//  MainWindowController.swift
//  Shut Up
//
//  Created by Ricky Romero on 10/20/19.
//  See LICENSE.md for license information.
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
    }
}

// MARK: NSWindowDelegate

extension MainWindowController: NSWindowDelegate {
    // Callback for when a sheet is being presented on the main window
    func window(_ window: NSWindow, willPositionSheet sheet: NSWindow, using rect: NSRect) -> NSRect {
        // Offset input rectangle so it sits on the top of the window
        let destRect = NSOffsetRect(rect, 0.0, window.frame.height - rect.origin.y)
        return destRect
    }
}
