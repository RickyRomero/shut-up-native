//
//  Whitelist.swift
//  Shut Up
//
//  Created by Ricky Romero on 6/16/20.
//  Copyright © 2020 Ricky Romero. All rights reserved.
//

import Foundation

class Whitelist {
    static var main = Whitelist()
    private init() {}
    
    private let file = EncryptedFile(
        fsPath: Info.whitelistUrl,
        bundleOrigin: Bundle.main.url(forResource: "domain-whitelist", withExtension: "json")!
    )
    
    static func parseDomain(from item: String) -> String? {
        guard item.count > 0 else { return nil }

        let item = item.lowercased()
        let detector = try! NSDataDetector(
            types: NSTextCheckingResult.CheckingType.link.rawValue
        )
        let match = detector.firstMatch(
            in: item,
            options: [],
            range: NSRange(location: 0, length: item.utf16.count)
        )

        // Try using NSDataDetector to see if we're dealing with something that looks
        // to the operating system like a link
        if let match = match {
            // It's a link if the match covers the whole string
            guard match.range.length == item.utf16.count else { return nil }

            // Attempt to parse the hostname out if the NSDataDetector found something
            if let parsedDomain = URL(string: item)?.host {
                return parsedDomain
            }
        }

        // Fallback tests, for weird TLDs
        // First check: Is it the correct length?
        guard item.count <= 253 else {
            print("Domain is too long.")
            return nil
        }
        
        // Second check: Does it have the correct number of dots?
        let subdivisions = item.components(separatedBy: ".").count - 1
        guard (1..<127).contains(subdivisions) else {
            print("Too few (or many) subdivisions used.")
            return nil
        }
        
        // Final check: Does it pass a regex test?
        let domainNameRegex = try! NSRegularExpression(
            pattern: "^(?:[a-z0-9\\-]{1,63}\\.){1,126}[a-z0-9\\-]{1,63}$",
            options: NSRegularExpression.Options()
        )
        let domainNameCount = domainNameRegex.numberOfMatches(
            in: item,
            options: [],
            range: NSMakeRange(0, item.count)
        )
        guard domainNameCount > 0 else {
            print("Didn't find a domain name.")
            return nil
        }
        
        return item
    }
}
