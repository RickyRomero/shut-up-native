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
    var succeeded = false
    private var _error: Error?
    var error: Error? {
        get { _error }
        set { _error = (_error == nil ? newValue : _error) }
    }

    func obtainLockAndTakeActionIf() -> Bool {
        print(#function)
        do {
            try Crypto.main.requestKeychainUnlock()

            return Crypto.main.preCatalinaKeysPresent || !Crypto.main.requiredKeysPresent
        } catch {
            self.error = error
            return false
        }
    }

    func action() {
        print(#function)
        do {
            if Crypto.main.preCatalinaKeysPresent {
                print("Pre-Catalina keys present. Migrating....................................")
                try Crypto.main.migratePreCatalinaKeys()
            } else if !Crypto.main.requiredKeysPresent {
                print("Required keys not present. Generating....................................")
                try Crypto.main.generateKeyPair()
            }
        } catch {
            self.error = error
        }
    }

    func finally() {
        print(#function)
        print("Finished crypto setup.")
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
    func bootstrap() {
        guard !bootstrapStarted else { return }

        bootstrapStarted = true

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
                print(originalData.base64EncodedString())
                let encryptedData = try Crypto.main.transform(with: .encryption, data: originalData)
                print(encryptedData.base64EncodedString())
                let reconstitutedData = try Crypto.main.transform(with: .decryption, data: encryptedData)
                print(reconstitutedData.base64EncodedString())
                success = true
            } catch {
                print(error.localizedDescription)
            }

            print("DONE??????????")
            let timestamp = String(Date().timeIntervalSince1970)
            let id = Info.bundleId
            let destUrl = Info.containerUrl.appendingPathComponent("\(id).\(timestamp).\(success).txt")

            try? "".write(to: destUrl, atomically: true, encoding: .utf8)
            NSLog("bootstrap Shut Up Core \(Info.bundleId)")
        }
    }

    func restart() {
        // Prevent a case where multiple things could try to reset at once,
        // kicking off multiple bootstrap sessions
        guard bootstrapAttempted else { return }

        bootstrapStarted = false
        bootstrapAttempted = false
        bootstrap()
    }

    func reset() {}
}
