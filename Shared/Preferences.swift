//
//  Preferences.swift
//  shutup
//
//  Created by Ricky Romero on 5/23/20.
//  Copyright © 2020 Ricky Romero. All rights reserved.
//

import Foundation

protocol PrefsUpdateDelegate {
    func prefsDidUpdate()
}

final class Preferences {
    static let main = Preferences()
    private init () {}

    let suitePrefs = UserDefaults.init(suiteName: Info.groupId)!
    var setupStarted = false
    var setupRun = false
    let latestSetupAssistantBuild = 1

    func setup() {
        guard !setupStarted else { return }
        setupStarted = true

        switch lastBuildRun {
            case 0:
                showInMenu = true
                automaticWhitelisting = true
            default:
                break
        }

        lastBuildRun = Info.buildNum
        setupRun = true

        _delegate?.prefsDidUpdate()
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

    var needsSetupAssistant: Bool {
        setupAssistantCompleteForBuild < latestSetupAssistantBuild
    }
}
