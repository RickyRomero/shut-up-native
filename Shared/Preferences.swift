//
//  Preferences.swift
//  shutup
//
//  Created by Ricky Romero on 5/23/20.
//  See LICENSE.md for license information.
//

import Foundation

protocol PrefsUpdateDelegate: AnyObject {
    func prefsDidUpdate()
}

final class Preferences {
    static let main = Preferences()
    private init() {}

    let suitePrefs = UserDefaults(suiteName: Info.groupId)!
    var setupStarted = false
    var setupRun = false
    let latestSetupAssistantBuild = 1

    func setDefaults() {
        guard !setupStarted else { return }
        setupStarted = true

        suitePrefs.register(defaults: [
            "lastBuildRun": 0,
            "setupAssistantCompleteForBuild": 0,
            "automaticWhitelisting": true,
            "showInMenu": true,
            "etag": "",
            "lastStylesheetUpdate": 0.0,
            "lastUpdateMethod": "automatic"
        ])

        switch lastBuildRun {
        case 0:
            showInMenu = true
            automaticWhitelisting = true
            fallthrough
        case 1 ... 11:
            lastUpdateMethod = "automatic"
        default:
            break
        }

        lastBuildRun = Info.buildNum
        setupRun = true

        delegate?.prefsDidUpdate()
    }

    func reset() {
        suitePrefs.removePersistentDomain(forName: Info.groupId)
        suitePrefs.synchronize()
    }

    private var _delegate: PrefsUpdateDelegate?
    var delegate: PrefsUpdateDelegate? {
        get { _delegate }
        set {
            _delegate = newValue
            if setupRun { _delegate?.prefsDidUpdate() }
        }
    }

    var lastBuildRun: Int {
        get { suitePrefs.integer(forKey: "lastBuildRun") }
        set { suitePrefs.set(newValue, forKey: "lastBuildRun") }
    }

    var setupAssistantCompleteForBuild: Int {
        get { suitePrefs.integer(forKey: "setupAssistantCompleteForBuild") }
        set { suitePrefs.set(newValue, forKey: "setupAssistantCompleteForBuild") }
    }

    var automaticWhitelisting: Bool {
        get { suitePrefs.bool(forKey: "automaticWhitelisting") }
        set { suitePrefs.set(newValue, forKey: "automaticWhitelisting") }
    }

    var showInMenu: Bool {
        get { suitePrefs.bool(forKey: "showInMenu") }
        set { suitePrefs.set(newValue, forKey: "showInMenu") }
    }

    var etag: String {
        get { suitePrefs.string(forKey: "etag") ?? "" }
        set { suitePrefs.set(newValue, forKey: "etag") }
    }

    var lastStylesheetUpdate: Date {
        get {
            let stamp = suitePrefs.double(forKey: "lastStylesheetUpdate")
            return Date(timeIntervalSince1970: stamp)
        }
        set {
            let stamp = newValue.timeIntervalSince1970
            suitePrefs.set(stamp, forKey: "lastStylesheetUpdate")
        }
    }

    var lastUpdateMethod: String {
        get { suitePrefs.string(forKey: "lastUpdateMethod") ?? "automatic" }
        set { suitePrefs.set(newValue, forKey: "lastUpdateMethod") }
    }

    var needsSetupAssistant: Bool {
        setupAssistantCompleteForBuild < latestSetupAssistantBuild
    }
}
