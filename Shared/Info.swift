//
//  Info.swift
//  shutup
//
//  Created by Ricky Romero on 10/6/19.
//  Copyright © 2019 Ricky Romero. All rights reserved.
//

import Cocoa

struct Info {
    static let containingBundleId = "com.rickyromero.shutup" // HACK: Can't determine programmatically
    static let helperBundleId = "\(Info.containingBundleId).helper"
    static let blockerBundleId = "\(Info.containingBundleId).blocker"

    static let productName = readBundleKey(kCFBundleNameKey)
    static let version = readBundleKey("CFBundleShortVersionString")
    static let buildNum = Int(readBundleKey(kCFBundleVersionKey))!

    static let bundleId = Bundle.main.bundleIdentifier!
    static let teamId = readBundleKey("TeamIdentifierPrefix")
    static let groupId = "\(Info.teamId)\(Info.containingBundleId)"

    static let isApp = Info.bundleId == Info.containingBundleId

    static let containerUrl = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: Info.groupId)!
    static let tempBlocklistUrl = Info.containerUrl.appendingPathComponent("blocklist.json")
    static let whitelistUrl = Info.containerUrl.appendingPathComponent("domain-whitelist.json.enc")
    static let localCssUrl = Info.containerUrl.appendingPathComponent("shutup.css.enc")

    private static func readBundleKey(_ key: CFString) -> String {
        Bundle.main.infoDictionary![key as String]! as! String
    }

    private static func readBundleKey(_ key: String) -> String {
        Bundle.main.infoDictionary![key]! as! String
    }
}
