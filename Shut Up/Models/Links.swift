//
//  Links.swift
//  Shut Up
//
//  Created by Ricky Romero on 11/3/19.
//  See LICENSE.md for license information.
//

import SafariServices

protocol Link {
    var destination: URL! { get }
    var menuTitle: String { get }

    func open()
}

struct BasicLink: Link {
    let destination: URL!
    let menuTitle: String

    init (menuTitle: String, dest: String) {
        destination = URL(string: dest)
        self.menuTitle = menuTitle
    }

    func open() {
        NSWorkspace.shared.open(destination)
    }
}

struct ExtensionLink: Link {
    let destination: URL!
    let preferredBrowser: WebBrowser
    let menuTitle: String

    init (menuTitle: String, dest: String, browser: WebBrowser) {
        preferredBrowser = browser
        destination = URL(string: dest)
        self.menuTitle = menuTitle
    }

    // Try to open the link with its matching browser.
    func open() {
        let ws = NSWorkspace.shared
        var bundleId: String?

        switch preferredBrowser {
            case .chrome: bundleId = "com.google.chrome"
            case .firefox: bundleId = "org.mozilla.firefox"
            case .edge: bundleId = "com.microsoft.edgemac"
            case .opera: bundleId = "com.operasoftware.opera"
            default: bundleId = nil
        }

        if let bundleId = bundleId {
            if #available(macOS 10.15, *) {
                let appLocation = ws.urlForApplication(withBundleIdentifier: bundleId)

                if let appLocation = appLocation {
                    ws.open(
                        [destination],
                        withApplicationAt: appLocation,
                        configuration: NSWorkspace.OpenConfiguration()
                    ) { (_, error) in
                        if error != nil {
                            ws.open(self.destination)
                        }
                    }
                } else {
                    ws.open(destination)
                }
            } else {
                let linkOpened = ws.open(
                    [destination],
                    withAppBundleIdentifier: bundleId,
                    options: [],
                    additionalEventParamDescriptor: nil,
                    launchIdentifiers: nil
                )
                if !linkOpened {
                    ws.open(destination)
                }
            }
        } else {
            ws.open(destination)
        }
    }
}

struct LinkCollection {
    let items: [Link]

    func open(by menuItem: NSMenuItem) {
        let target = items.filter { $0.menuTitle == menuItem.title } [0]
        target.open()
    }

    func open(by browser: WebBrowser) {
        let extensionLinks = items.filter { $0 is ExtensionLink } as! [ExtensionLink]
        let linkForBrowser = extensionLinks.filter { $0.preferredBrowser == browser } [0]
        linkForBrowser.open()
    }
}

struct Links {
    static let collection = LinkCollection(items: [
        ExtensionLink(
            menuTitle: "Shut Up for Chrome",
            dest: "https://chrome.google.com/webstore/detail/shut-up-comment-blocker/oklfoejikkmejobodofaimigojomlfim",
            browser: .chrome
        ),
        ExtensionLink(
            menuTitle: "Shut Up for Firefox",
            dest: "https://addons.mozilla.org/en-US/firefox/addon/shut-up-comment-blocker/",
            browser: .firefox
        ),
        ExtensionLink(
            menuTitle: "Shut Up for Edge",
            dest: "https://microsoftedge.microsoft.com/addons/detail/giifliakcgfijgkejmenachfdncbpalp",
            browser: .edge
        ),
        ExtensionLink(
            menuTitle: "Shut Up for Opera",
            dest: "https://github.com/panicsteve/shutup-css#installation-on-opera",
            browser: .opera
        ),
        BasicLink(
            menuTitle: "Shut Up for iPhone and iPad",
            dest: "https://apps.apple.com/app/id1015043880"
        ),
        BasicLink(
            menuTitle: "Release Notes",
            dest: "https://rickyromero.com/shutup/release-notes/"
        ),
        BasicLink(
            menuTitle: "Privacy Policy",
            dest: "https://rickyromero.com/shutup/privacy/"
        ),
    ])

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
