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
    static let target = "https://apps.apple.com/app/id1015043880"
    static let targetUrl = URL(string: target)!
    var sharingPicker: NSSharingServicePicker!
    override var acceptsFirstResponder: Bool { true }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let qrCodeData = MobileAppViewController.target.data(using: .ascii)

        if let filter = CIFilter(name: "CIQRCodeGenerator") {
            filter.setValue(qrCodeData, forKey: "inputMessage")
            let transform = CGAffineTransform(scaleX: 8, y: 8)
            if let output = filter.outputImage?.transformed(by: transform) {
                let rep = NSCIImageRep(ciImage: output)
                let nsImage = NSImage(size: rep.size)
                nsImage.addRepresentation(rep)

                qrCodeContainer.image = nsImage
            }
        }

        sharingPicker = NSSharingServicePicker(
            items: [MobileAppViewController.targetUrl]
        )
    }

    override func viewWillAppear() {
        super.viewWillAppear()
        view.window?.styleMask.remove(.resizable)
        view.window?.preventsApplicationTerminationWhenModal = false
        view.window?.makeFirstResponder(view)
    }

    @IBAction func performClose(_ sender: Any) {
        view.window?.close()
    }

    @IBAction func terminate(_ sender: Any) {
        view.window?.close()
        NSApp.terminate(sender)
    }
    
    @IBAction func showSharingPicker(_ sender: NSButton) {
        sharingPicker.show(
            relativeTo: .zero,
            of: sender,
            preferredEdge: .minY
        )
    }
}
