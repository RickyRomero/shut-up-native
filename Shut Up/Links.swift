//
//  Links.swift
//  Shut Up
//
//  Created by Ricky Romero on 11/3/19.
//  Copyright © 2019 Ricky Romero. All rights reserved.
//

import SafariServices

struct Links {
    static let lookupTable = [
        "Shut Up for Chrome": "https://chrome.google.com/webstore/detail/shut-up-comment-blocker/oklfoejikkmejobodofaimigojomlfim",
        "Shut Up for Firefox": "https://addons.mozilla.org/en-US/firefox/addon/shut-up-comment-blocker/",
        "Shut Up for Edge": "https://microsoftedge.microsoft.com/addons/detail/giifliakcgfijgkejmenachfdncbpalp",
        "Shut Up for Opera": "https://addons.opera.com/en/extensions/details/shut-up-comment-blocker/",
        "Shut Up for iPhone and iPad": "https://apps.apple.com/app/id1015043880",
        "Release Notes": "https://rickyromero.com/shutup/release-notes/",
        "Privacy Policy": "https://rickyromero.com/shutup/privacy/"
    ]

    static func composeEmail() {
        let knownSafariReleases = [
            SafariRelease(services: .version10_0, userFacingVersion: "10.0"),
            SafariRelease(services: .version10_1, userFacingVersion: "10.1"),
            SafariRelease(services: .version11_0, userFacingVersion: "11.0"),
            SafariRelease(services: .version12_0, userFacingVersion: "12.0"),
            SafariRelease(services: .version12_1, userFacingVersion: "12.1"),
            SafariRelease(services: .version13_0, userFacingVersion: "13.0 or greater")
        ]
        var highestSafariVersion = "10.0"
        for release in knownSafariReleases {
            if SFSafariServicesAvailable(release.services) {
                highestSafariVersion = release.userFacingVersion
            }
        }

        var macosVersion = ProcessInfo.processInfo.operatingSystemVersionString
        macosVersion = macosVersion.replacingOccurrences(
            of: "Version ", with: "", options: NSString.CompareOptions.literal, range: nil
        )

        let urlComps = NSURLComponents(string: "mailto:shutup@fwd.rickyromero.com")!
        let queryItems = [
            URLQueryItem(name: "subject", value: "Shut Up Feedback (macOS Safari)"),
            URLQueryItem(name: "body", value: """


            ---

            App version: \(Info.version) (\(Info.buildNum))
            macOS version: \(macosVersion)
            SafariServices version: \(highestSafariVersion)

            [If reporting a problem, please be as specific as you can so I can diagnose it. Thank you! -Ricky]
            """)
        ]
        urlComps.queryItems = queryItems
        let url = urlComps.url!

        NSWorkspace.shared.open(url)
    }
}

struct SafariRelease {
    let services: SFSafariServicesVersion
    let userFacingVersion: String
}
