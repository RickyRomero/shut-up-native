//
//  WelcomeViewController.swift
//  Shut Up
//
//  Created by Ricky Romero on 5/24/20.
//  See LICENSE.md for license information.
//

import Cocoa

class WelcomeViewController: NSViewController, PageContentResponder {
    @IBOutlet var babyBrowser: NSImageView!
    @IBOutlet var babyBrowserAtBottom: NSLayoutConstraint!
    var delegate: WelcomePageDelegate?

    override func viewDidLoad() {
        NotificationCenter.default.addObserver(
            forName: NSColor.systemColorsDidChangeNotification,
            object: nil,
            queue: .main,
            using: updateBabyBrowserTintColor(_:)
        )

        updateBabyBrowserTintColor(nil)

        babyBrowserAtBottom.isActive = false
        babyBrowser.alphaValue = 0.0

        Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { _ in
            NSAnimationContext.runAnimationGroup({ context in
                context.duration = 1.333
                context.allowsImplicitAnimation = true

                self.babyBrowserAtBottom.isActive = true
                self.babyBrowser.alphaValue = 1.0
                self.view.window?.layoutIfNeeded()
            })
        }
    }

    func updateBabyBrowserTintColor(_: Notification?) {
        let isAqua = NSColor.currentControlTint != NSControlTint.graphiteControlTint
        let appearance = isAqua ? "Aqua" : "Graphite"

        babyBrowser.image = NSImage(named: "Baby Browser \(appearance)")
    }
}
