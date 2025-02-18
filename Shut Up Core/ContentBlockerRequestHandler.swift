//
//  ContentBlockerRequestHandler.swift
//  blocker
//
//  Created by Ricky Romero on 9/2/19.
//  See LICENSE.md for license information.
//

import Foundation
import UniformTypeIdentifiers

class ContentBlockerRequestHandler: NSObject, NSExtensionRequestHandling {
    func beginRequest(with context: NSExtensionContext) {
        Setup.main.bootstrap {}

        // Get coalesced rules from stylesheet and whitelist
        let provider = ContentBlockerProvider()
        let rules = provider.coalesce()

        // Begin stylesheet update if necessary
        Stylesheet.main.update(completionHandler: nil)

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
            typeIdentifier: UTType.json.identifier
        )

        let item = NSExtensionItem()
        item.attachments = [attachment]

        context.completeRequest(returningItems: [item], completionHandler: nil)
    }
}

func showError(_: Error) {}
