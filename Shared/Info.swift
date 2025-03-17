//
//  Info.swift
//  shutup
//
//  Created by Ricky Romero on 10/6/19.
//  See LICENSE.md for license information.
//

import Cocoa

enum Info {
    static let containingBundleId = "com.rickyromero.shutup" // WORKAROUND: Can't determine programmatically
    static let helperBundleId = "\(containingBundleId).helper"
    static let blockerBundleId = "\(containingBundleId).blocker"

    static let productName = readBundleKey(kCFBundleNameKey)
    static let version = readBundleKey("CFBundleShortVersionString")
    static let buildNum = Int(readBundleKey(kCFBundleVersionKey))!

    static let bundleId = Bundle.main.bundleIdentifier!
    static let teamId = readBundleKey("TeamIdentifierPrefix")
    static let groupId = "\(teamId)\(containingBundleId)"

    static let isApp = bundleId == containingBundleId

    static let containerUrl = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: Info.groupId)!
    static let tempBlocklistUrl = containerUrl.appendingPathComponent("blocklist.json")
    static let whitelistUrl = containerUrl.appendingPathComponent("domain-whitelist.json.enc")
    static let localCssUrl = containerUrl.appendingPathComponent("shutup.css.enc")

    private static func readBundleKey(_ key: CFString) -> String {
        guard let value = Bundle.main.infoDictionary?[key as String] as? String else {
            // TODO: Instead of calling fatalError when the Info.plist key is missing, provide a fallback or throw an error
            fatalError("Expected key \(key) in Info.plist is missing or not a string")
        }
        return value
    }

    private static func readBundleKey(_ key: String) -> String {
        guard let value = Bundle.main.infoDictionary?[key] as? String else {
            // TODO: Rather than fatalError, handle the missing or invalid key scenario gracefully
            fatalError("Expected key \(key) in Info.plist is missing or not a string")
        }
        return value
    }
}
