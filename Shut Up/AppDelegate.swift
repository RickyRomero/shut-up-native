//
//  AppDelegate.swift
//  shutup
//
//  Created by Ricky Romero on 9/2/19.
//  Copyright © 2019 Ricky Romero. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        Setup.main.bootstrap()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { true }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    @IBAction func didChooseLinkItem(_ sender: NSMenuItem) {
        let destination = Links.lookupTable[sender.title]!
        let url = URL(string: destination)!

        NSWorkspace.shared.open(url)
    }

    @IBAction func didChooseContactMenuItem(_ sender: NSMenuItem) {
        Links.composeEmail()
    }
}

// MARK: ErrorRecoveryDelegate

extension AppDelegate: ErrorRecoveryDelegate {
    func attemptRecovery(from error: Error, with option: RecoveryOption) -> Bool {
        do {
            switch option {
                case .tryAgain:
                    throw MessagingError(FileError.checkingFreeSpace)
                case .ok:
                    break
                case .quit:
                    NSApp.terminate(nil)
                case .reset:
                    break;
            }
            if option == .tryAgain {
//                try something()
                throw FileError.checkingFreeSpace
            }
        } catch {
            NSApp.presentError(error)
        }
        
        return true
    }
    
    func application(_ application: NSApplication, willPresentError error: Error) -> Error {
        return DelegatingRecoverableError(recoveringFrom: error, with: self)
    }
}
