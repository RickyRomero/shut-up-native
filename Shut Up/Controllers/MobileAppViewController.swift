//
//  MobileAppViewController.swift
//  Shut Up
//
//  Created by Ricky Romero on 6/15/20.
//  Copyright © 2020 Ricky Romero. All rights reserved.
//

import Cocoa

class MobileAppViewController: NSViewController {
    @IBOutlet var qrCodeContainer: NSImageView!

    override func viewDidLoad() {
        super.viewDidLoad()

        let targetUrl = "https://apps.apple.com/app/id1015043880".data(using: .ascii)

        if let filter = CIFilter(name: "CIQRCodeGenerator") {
            filter.setValue(targetUrl, forKey: "inputMessage")
            let transform = CGAffineTransform(scaleX: 20, y: 20)
            if let output = filter.outputImage?.transformed(by: transform) {
                let rep = NSCIImageRep(ciImage: output)
                let nsImage = NSImage(size: rep.size)
                nsImage.addRepresentation(rep)

                qrCodeContainer.image = nsImage
            }
        }
    }

    override func viewWillAppear() {
        super.viewWillAppear()
        view.window?.styleMask.remove(.resizable)
        view.window?.preventsApplicationTerminationWhenModal = false
    }

    @IBAction func performClose(_ sender: Any) {
        view.window?.close()
    }

    @IBAction func terminate(_ sender: Any) {
        view.window?.close()
        NSApp.terminate(sender)
    }
}
