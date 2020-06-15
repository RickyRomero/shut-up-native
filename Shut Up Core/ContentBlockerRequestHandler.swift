//
//  ContentBlockerRequestHandler.swift
//  blocker
//
//  Created by Ricky Romero on 9/2/19.
//  Copyright © 2019 Ricky Romero. All rights reserved.
//

import Foundation

class ContentBlockerRequestHandler: NSObject, NSExtensionRequestHandling {

    override init() {
        super.init()
        NSLog("init Shut Up Core \(Info.bundleId)")

        Setup.main.bootstrap {}

        print("Should be fetching now")
        Stylesheet.main.update(force: false) { error in
            print("done")
        }
    }

    func beginRequest(with context: NSExtensionContext) {
        NSLog("beginRequest Shut Up Core \(Info.bundleId)")
        guard FileManager.default.fileExists(atPath: Info.tempBlocklistUrl.path) else {
            NSLog("cancelRequest Shut Up Core \(Info.bundleId)")
            context.cancelRequest(withError: UnknownError.unknown)
            return
        }

        let attachment = NSItemProvider(contentsOf: Info.tempBlocklistUrl)!
        
        let item = NSExtensionItem()
        item.attachments = [attachment]

        NSLog("Fulfilling request @ Shut Up Core \(Info.bundleId)")
        context.completeRequest(returningItems: [item]) { _ in
            NSLog("Deleting file @ Shut Up Core \(Info.bundleId)")
            try? FileManager.default.removeItem(at: Info.tempBlocklistUrl)
            NSLog("File deleted @ Shut Up Core \(Info.bundleId)")
        }
    }
    
}
