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

    var setupStarted = false
    var setupRun = false

    func setDefaults() {
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
        lastOsVersionRun = ProcessInfo.processInfo.operatingSystemVersion
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
        get { UserDefaults.standard.integer(forKey: "lastBuildRun") }
        set { UserDefaults.standard.set(newValue, forKey: "lastBuildRun") }
    }

    var lastOsVersionRun: OperatingSystemVersion {
        get {
            let major = UserDefaults.standard.integer(forKey: "lastOsMajorVersionRun")
            let minor = UserDefaults.standard.integer(forKey: "lastOsMinorVersionRun")
            let patch = UserDefaults.standard.integer(forKey: "lastOsPatchVersionRun")
            return OperatingSystemVersion(majorVersion: major, minorVersion: minor, patchVersion: patch)
        }
        set {
            UserDefaults.standard.set(newValue.majorVersion, forKey: "lastOsMajorVersionRun")
            UserDefaults.standard.set(newValue.minorVersion, forKey: "lastOsMinorVersionRun")
            UserDefaults.standard.set(newValue.patchVersion, forKey: "lastOsPatchVersionRun")
        }
    }

    var setupAssistantCompleteForBuild: Int {
        get { UserDefaults.standard.integer(forKey: "setupAssistantCompleteForBuild") }
        set { UserDefaults.standard.set(newValue, forKey: "setupAssistantCompleteForBuild") }
    }

    var automaticWhitelisting: Bool {
        get { UserDefaults.standard.bool(forKey: "automaticWhitelisting") }
        set { UserDefaults.standard.set(newValue, forKey: "automaticWhitelisting") }
    }

    var showInMenu: Bool {
        get { UserDefaults.standard.bool(forKey: "showInMenu") }
        set { UserDefaults.standard.set(newValue, forKey: "showInMenu") }
    }

    var etag: String {
        get { UserDefaults.standard.string(forKey: "etag") ?? "" }
        set { UserDefaults.standard.set(newValue, forKey: "etag") }
    }

    var lastStylesheetUpdate: Date {
        get {
            let stamp = UserDefaults.standard.double(forKey: "lastStylesheetUpdate")
            return Date(timeIntervalSince1970: stamp)
        }
        set {
            let stamp = newValue.timeIntervalSince1970
            UserDefaults.standard.set(stamp, forKey: "lastStylesheetUpdate")
        }
    }
}
