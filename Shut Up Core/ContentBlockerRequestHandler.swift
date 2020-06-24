//
//  ContentBlockerRequestHandler.swift
//  blocker
//
//  Created by Ricky Romero on 9/2/19.
//  Copyright © 2019 Ricky Romero. All rights reserved.
//

import Foundation

class ContentBlockerRequestHandler: NSObject, NSExtensionRequestHandling {
    func beginRequest(with context: NSExtensionContext) {
        Setup.main.bootstrap {}

        Stylesheet.main.update(force: false, completionHandler: nil)

        // Get coalesced rules from stylesheet and whitelist
        let provider = ContentBlockerProvider()
        let rules = provider.coalesce()

        // Set up JSON encoder with kebab-cased keys
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .custom { keyPath -> CodingKey in
            KebabKey(stringValue: keyPath.last!.stringValue)!
        }

        // Encode the JSON data and respond to the request
        guard let jsonData = try? encoder.encode(rules) else {
            context.cancelRequest(withError: UnknownError.unknown)
            return
        }

        let attachment = NSItemProvider(
            item: jsonData as NSData,
            typeIdentifier: kUTTypeJSON as String
        )

        let item = NSExtensionItem()
        item.attachments = [attachment]

        context.completeRequest(returningItems: [item], completionHandler: nil)
    }
}

func showError(_: Error) {}
