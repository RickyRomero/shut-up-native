//
//  Links.swift
//  Shut Up
//
//  Created by Ricky Romero on 11/3/19.
//  See LICENSE.md for license information.
//

import SafariServices

protocol Link {
    var id: String { get }
    var destination: URL! { get }

    func open()
}

struct BasicLink: Link {
    let id: String
    let destination: URL!

    init(id: String, dest: String) {
        self.id = id
        destination = URL(string: dest)
    }

    func open() {
        NSWorkspace.shared.open(destination)
    }
}

struct ExtensionLink: Link {
    let id: String
    let destination: URL!
    let preferredBrowser: WebBrowser

    init(id: String, dest: String, browser: WebBrowser) {
        self.id = id
        preferredBrowser = browser
        destination = URL(string: dest)
    }

    // Try to open the link with its matching browser.
    func open() {
        let ws = NSWorkspace.shared
        let bundleId: String? = switch preferredBrowser {
        case .chrome: "com.google.chrome"
        case .firefox: "org.mozilla.firefox"
        case .edge: "com.microsoft.edgemac"
        case .opera: "com.operasoftware.opera"
        case .brave: "com.brave.browser"
        default: nil
        }

        if let bundleId {
            let appLocation = ws.urlForApplication(withBundleIdentifier: bundleId)

            if let appLocation {
                ws.open(
                    [destination],
                    withApplicationAt: appLocation,
                    configuration: NSWorkspace.OpenConfiguration()
                ) { _, error in
                    if error != nil {
                        ws.open(destination)
                    }
                }
            } else {
                ws.open(destination)
            }

        } else {
            ws.open(destination)
        }
    }
}

struct LinkCollection {
    let items: [Link]

    func open(by menuItem: NSMenuItem) {
        let target = items.filter { $0.id == menuItem.identifier?.rawValue }[0]
        target.open()
    }

    func open(by browser: WebBrowser) {
        let extensionLinks = items.compactMap { $0 as? ExtensionLink }
        guard let linkForBrowser = extensionLinks.first(where: { $0.preferredBrowser == browser }) else {
            return
        }
        linkForBrowser.open()
    }
}

enum Links {
    static let collection = LinkCollection(items: [
        ExtensionLink(
            id: "shut_up_brave",
            dest: "https://chrome.google.com/webstore/detail/shut-up-comment-blocker/oklfoejikkmejobodofaimigojomlfim",
            browser: .brave
        ),
        ExtensionLink(
            id: "shut_up_chrome",
            dest: "https://chrome.google.com/webstore/detail/shut-up-comment-blocker/oklfoejikkmejobodofaimigojomlfim",
            browser: .chrome
        ),
        ExtensionLink(
            id: "shut_up_edge",
            dest: "https://microsoftedge.microsoft.com/addons/detail/giifliakcgfijgkejmenachfdncbpalp",
            browser: .edge
        ),
        ExtensionLink(
            id: "shut_up_firefox",
            dest: "https://addons.mozilla.org/en-US/firefox/addon/shut-up-comment-blocker/",
            browser: .firefox
        ),
        ExtensionLink(
            id: "shut_up_opera",
            dest: "https://github.com/panicsteve/shutup-css#installation-on-opera",
            browser: .opera
        ),
        BasicLink(
            id: "shut_up_ios",
            dest: "https://apps.apple.com/app/id1015043880"
        ),
        BasicLink(
            id: "release_notes",
            dest: "https://rickyromero.com/shutup/release-notes/"
        ),
        BasicLink(
            id: "privacy_policy",
            dest: "https://rickyromero.com/shutup/privacy/"
        ),
        BasicLink(
            id: "github_source",
            dest: "https://github.com/RickyRomero/shut-up-native"
        ),
    ])

    static func composeEmail() {
        let knownSafariReleases = [
            SafariRelease(services: .version10_0, userFacingVersion: "10.0"),
            SafariRelease(services: .version10_1, userFacingVersion: "10.1"),
            SafariRelease(services: .version11_0, userFacingVersion: "11.0"),
            SafariRelease(services: .version12_0, userFacingVersion: "12.0"),
            SafariRelease(services: .version12_1, userFacingVersion: "12.1"),
            SafariRelease(services: .version13_0, userFacingVersion: "13.0 or greater"),
        ]
        let highestSafariVersion = knownSafariReleases
            .filter { SFSafariServicesAvailable($0.services) }
            .last?.userFacingVersion ?? "10.0"

        let safariAppVersion: String = {
            if let safariURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.apple.Safari"),
               let safariBundle = Bundle(url: safariURL),
               let version = safariBundle.infoDictionary?["CFBundleShortVersionString"] as? String
            {
                return version
            }
            return "Unknown"
        }()

        let macosVersion: String = {
            let version = ProcessInfo.processInfo.operatingSystemVersionString
            return version.replacingOccurrences(of: "Version ", with: "", options: .literal, range: nil)
        }()

        let urlComps = NSURLComponents(string: "mailto:shutup@fwd.rickyromero.com")!
        let queryItems = [
            URLQueryItem(name: "subject", value: "Shut Up Feedback (macOS Safari)"),
            URLQueryItem(name: "body", value: """


            ---

            App version: \(Info.version) (\(Info.buildNum))
            macOS version: \(macosVersion)
            Safari app version: \(safariAppVersion)
            SafariServices version: \(highestSafariVersion)
            Stylesheet last updated: \(Preferences.main.lastStylesheetUpdate)

            [If reporting a problem, please be as specific as you can so I can diagnose it. Thank you! — Ricky]
            """),
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
