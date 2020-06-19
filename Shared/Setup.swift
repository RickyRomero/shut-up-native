//
//  Setup.swift
//  shutup
//
//  Created by Ricky Romero on 10/6/19.
//  Copyright © 2019 Ricky Romero. All rights reserved.
//

import Cocoa

final class CryptoSetupCla: ConditionalLockAction {
    var queue: ClaQueue?
    var lock = LockFile(url: Info.containerUrl.appendingPathComponent("keychain.lock"))
    private var _error: Error?
    var error: Error? {
        get { _error }
        set { _error = (_error == nil ? newValue : _error) }
    }

    func obtainLockAndTakeActionIf() -> Bool {
        do {
            try Crypto.main.requestKeychainUnlock()

            return Crypto.main.preCatalinaKeysPresent || !Crypto.main.requiredKeysPresent
        } catch {
            self.error = error
            return false
        }
    }

    func action() {
        do {
            if Crypto.main.preCatalinaKeysPresent {
                try Crypto.main.migratePreCatalinaKeys()
            } else if !Crypto.main.requiredKeysPresent {
                try Crypto.main.generateKeyPair()
            }
        } catch {
            self.error = error
        }
    }
}

final class Setup {
    static var main = Setup()
    private init() {}

    // Safari extensions initialize and run in a way that's very unpredictable,
    // so we need some guarantee that this code runs once and only once per process.
    // https://forums.developer.apple.com/thread/113010#420523
    private var bootstrapStarted = false
    private var bootstrapAttempted = false

    func bootstrap(completionHandler: @escaping () -> Void) {
        bootstrap(false, completionHandler: completionHandler)
    }

    func bootstrap(_ resetKeyHeld: Bool, completionHandler: @escaping () -> Void) {
        guard !bootstrapStarted else { return }
        bootstrapStarted = true

        if queryAvailableSpace() < 200 * 1000 * 1000 { // 200 MB
            NSApp.presentError(MessagingError(FileError.checkingFreeSpace))
        }

        if resetKeyHeld {
            confirmReset()
        }

        Preferences.main.setDefaults()

//        var defaultKeychain: SecKeychain? = nil
//        let status = SecKeychainCopyDefault(&defaultKeychain)
//        print(status)
//        SecKeychainLock(defaultKeychain)

        ClaQueue([
            CryptoSetupCla()
        ]).run { (error: Error?) in
            self.bootstrapAttempted = true

            guard error == nil else {
                if Info.isApp {
                    NSApp.presentError(MessagingError(error!))
                }
                return
            }

            var success = false
            do {
                let originalData = "The quick brown fox jumps over the lazy dog.".data(using: .utf8)!
                let encryptedData = try Crypto.main.transform(with: .encryption, data: originalData)
                let reconstitutedData = try Crypto.main.transform(with: .decryption, data: encryptedData)
                success = true
            } catch {
                print(error.localizedDescription)
            }

            let timestamp = String(Date().timeIntervalSince1970)
            let id = Info.bundleId
            let destUrl = Info.containerUrl.appendingPathComponent("\(id).\(timestamp).\(success).txt")

            try? "".write(to: destUrl, atomically: true, encoding: .utf8)
            NSLog("bootstrap Shut Up Core \(Info.bundleId)")
            completionHandler()
        }
    }

    func restart() {
        // Prevent a case where multiple things could try to reset at once,
        // kicking off multiple bootstrap sessions
        guard bootstrapAttempted else { return }

        bootstrapStarted = false
        bootstrapAttempted = false
        bootstrap {}
    }

    func confirmReset() {
        let alert = NSAlert()
        alert.alertStyle = .critical
        alert.messageText = "Reset Shut Up?"
        alert.informativeText = "Resetting Shut Up will delete your preferences and whitelist. This will restore its original configuration. You cannot undo this action."
        let quitButton = alert.addButton(withTitle: "Quit")
        quitButton.keyEquivalent = ""
        alert.addButton(withTitle: "Reset Shut Up")

        let decision = alert.runModal()

        if decision == .alertFirstButtonReturn {
            NSApp.terminate(nil)
        } else {
            reset()
        }
    }

    func reset() {
        try? Crypto.main.clear(preCatalinaItems: true)
        try? Crypto.main.clear()
        Preferences.main.reset()
        Whitelist.main.reset()
        Stylesheet.main.reset()

        // Relaunch the app and stop this instance
        let resourceUrl = Bundle.main.resourceURL
        let appBundleUrl = resourceUrl?.deletingLastPathComponent().deletingLastPathComponent()

        if #available(macOS 10.15, *) {
            let config = NSWorkspace.OpenConfiguration()
            config.activates = true
            config.createsNewApplicationInstance = true
            NSWorkspace.shared.openApplication(
                at: appBundleUrl!,
                configuration: config,
                completionHandler: nil
            )
        } else {
            _ = try? NSWorkspace.shared.launchApplication(
                at: appBundleUrl!,
                options: .newInstance,
                configuration: [:]
            )
        }

        // Avoid NSApp.terminate(_:) here because it gives the app a chance to do other things
        exit(0)
    }

    func queryAvailableSpace() -> Int64 {
        let targetLocation = Info.containerUrl
        if #available(macOS 10.13, *) {
            let values = try! targetLocation.resourceValues(forKeys: [.volumeAvailableCapacityForImportantUsageKey])
            return values.volumeAvailableCapacityForImportantUsage!
        } else {
            let attributes = try! FileManager.default.attributesOfFileSystem(forPath: targetLocation.path)
            let freeSize = attributes[.systemFreeSize] as? NSNumber
            return freeSize!.int64Value
        }
    }
}
