//
//  BrowserBridge.swift
//  Shut Up
//
//  Created by Ricky Romero on 5/26/20.
//  See LICENSE.md for license information.
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

struct ExtensionState {
    let id: String
    let state: Bool?
    let error: Error?
}

class BrowserBridge {
    static var main = BrowserBridge()
    private init() {}

    private var extensionStates: [ExtensionState] = []
    private var stateCallbacks: [([ExtensionState]) -> Void] = []

    func requestExtensionStates(completionHandler: @escaping ([ExtensionState]) -> Void) {
        stateCallbacks.append(completionHandler)

        guard extensionStates.count == 0 else { return }

        SFSafariExtensionManager.getStateOfSafariExtension(withIdentifier: Info.helperBundleId) { state, error in
            self.updateExtensionState(Info.helperBundleId, state?.isEnabled, error)
        }
        SFContentBlockerManager.getStateOfContentBlocker(withIdentifier: Info.blockerBundleId) { state, error in
            self.updateExtensionState(Info.blockerBundleId, state?.isEnabled, error)
        }
    }

    func updateExtensionState(_ id: String, _ state: Bool?, _ error: Error?) {
        extensionStates.append(ExtensionState(id: id, state: state, error: error))
        guard extensionStates.count == 2 else { return }

        let states = extensionStates
        while stateCallbacks.count > 0 {
            let callback = stateCallbacks.removeFirst()
            DispatchQueue.main.async {
                callback(states)
            }
        }
        extensionStates.removeAll()
    }

    func showPrefs(for id: String, completionHandler: @escaping (Error?) -> Void) {
        SFSafariApplication.showPreferencesForExtension(withIdentifier: id) { error in
            DispatchQueue.main.async {
                completionHandler(error)
            }
        }
    }

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
            vendor.removeSubrange(2 ..< domainComponents)
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
