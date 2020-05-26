//
//  EnableExtensionsViewController.swift
//  Shut Up
//
//  Created by Ricky Romero on 5/25/20.
//  Copyright © 2020 Ricky Romero. All rights reserved.
//

import Cocoa
import SafariServices

class EnableExtensionsViewController: NSViewController {
    @IBOutlet var coreEnableButton: NSButton!
    @IBOutlet var helperEnableButton: NSButton!

    override func viewDidLoad() {
        super.viewDidLoad()

//        NotificationCenter.default.addObserver(
//            forName: NSApplication.didBecomeActiveNotification,
//            object: nil,
//            queue: .main,
//            using: checkExtensions(_:)
//        )
    }

//    func checkExtensions(_: Notification) {
//        SFContentBlockerManager.getStateOfContentBlocker(withIdentifier: Info.blockerBundleId) { blockerState, error in
//            if let error = error {
//                print(error.localizedDescription)
//                return
//            }
//            self.blockerEnabled = blockerState!.isEnabled
//
//            SFSafariExtensionManager.getStateOfSafariExtension(withIdentifier: Info.helperBundleId) { helperState, error in
//                self.helperEnabled = helperState!.isEnabled
//
//                DispatchQueue.main.async {
//                    self.respondToExtensionStates()
//                }
//            }
//        }
//    }

    @IBAction func coreButtonClicked(_ sender: NSButton) {
    }
    @IBAction func helperButtonClicked(_ sender: NSButton) {
    }
}
