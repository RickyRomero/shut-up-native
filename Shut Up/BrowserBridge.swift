//
//  BrowserBridge.swift
//  Shut Up
//
//  Created by Ricky Romero on 5/26/20.
//  Copyright © 2020 Ricky Romero. All rights reserved.
//

import SafariServices

enum WebBrowser {
    case safari
    case chrome
    case firefox
    case edge
    case opera
    case unknown
}

class BrowserBridge {
    static var main = BrowserBridge()
    private init () {}

    var defaultBrowser: WebBrowser {
        let testUrl = URL(string: "https://rickyromero.com/")!

        guard let defaultBrowserUrl = NSWorkspace.shared.urlForApplication(toOpen: testUrl) else {
            return .unknown
        }

        let browserBundle = Bundle(url: defaultBrowserUrl)
        let domain = browserBundle?.bundleIdentifier?.lowercased()
        guard var vendor = domain?.split(separator: ".", maxSplits: 2) else {
            return .unknown
        }

        if vendor.count > 2 {
            let domainComponents = vendor.count
            vendor.removeSubrange(2..<domainComponents)
        }

        switch vendor.joined(separator: ".") {
            case "com.apple": return .safari
            case "com.google": return .chrome
            case "org.mozilla": return .firefox
            case "com.microsoft": return .edge
            case "com.operasoftware": return .opera
            default: return .unknown
        }
    }

    var defaultBrowserName: String {
        let browserNameMap: [WebBrowser: String] = [
            .safari: "Safari",
            .chrome: "Chrome",
            .firefox: "Firefox",
            .edge: "Edge",
            .opera: "Opera",
            .unknown: "Unknown"
        ]
        return browserNameMap[defaultBrowser]!
    }
}
