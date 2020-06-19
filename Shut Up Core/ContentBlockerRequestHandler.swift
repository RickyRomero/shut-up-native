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
        Setup.main.bootstrap {}

        Stylesheet.main.update(force: false) { error in
            print("done")
        }
    }

    func beginRequest(with context: NSExtensionContext) {
        guard FileManager.default.fileExists(atPath: Info.tempBlocklistUrl.path) else {
            context.cancelRequest(withError: UnknownError.unknown)
            return
        }

        let attachment = NSItemProvider(contentsOf: Info.tempBlocklistUrl)!
        
        let item = NSExtensionItem()
        item.attachments = [attachment]

        context.completeRequest(returningItems: [item]) { _ in
            try? FileManager.default.removeItem(at: Info.tempBlocklistUrl)
        }
    }
    
}
