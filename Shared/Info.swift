//
//  Info.swift
//  shutup
//
//  Created by Ricky Romero on 10/6/19.
//  See LICENSE.md for license information.
//

import Cocoa

enum Info {
    static let containingBundleId = "com.rickyromero.shutup" // HACK: Can't determine programmatically
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
        Bundle.main.infoDictionary![key as String]! as! String
    }

    private static func readBundleKey(_ key: String) -> String {
        Bundle.main.infoDictionary![key]! as! String
    }
}
