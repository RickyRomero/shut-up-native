//
//  EncryptedFile.swift
//  shutup
//
//  Created by Ricky Romero on 5/13/20.
//  Copyright © 2020 Ricky Romero. All rights reserved.
//

import Cocoa

final class EncryptedFileCla: ConditionalLockAction {
    var queue: ClaQueue?
    var lock: LockFile
    private var _error: Error?
    var error: Error? {
        get { _error }
        set { _error = (_error == nil ? newValue : _error) }
    }
    let sensitiveAction: () throws -> Void

    init(for file: URL, onLockObtained: @escaping () throws -> Void) {
        lock = LockFile(url: file.appendingPathExtension("lock"))
        sensitiveAction = onLockObtained
    }

    func obtainLockAndTakeActionIf() -> Bool {
        do {
            try Crypto.main.requestKeychainUnlock()
            return Crypto.main.requiredKeysPresent
        } catch {
            self.error = error
            return false
        }
    }

    func action() {
        do {
            try sensitiveAction()
        } catch {
            self.error = error
        }
    }
}

final class EncryptedFile {
    let fsLocation: URL
    let bundleOrigin: URL

    var mostRecentlySeenModification: Date?
    var lastModified: Date? {
        let attributes = try? FileManager.default.attributesOfItem(atPath: fsLocation.path)
        return attributes?[.modificationDate] as? Date
    }

    var cache: Data?
    var externalUpdateOccurred: ((Data) -> Void)?
    var initCallback: (() -> Void)?

    init(fsLocation: URL, bundleOrigin: URL, completionHandler: @escaping () -> Void) {
        self.fsLocation = fsLocation
        self.bundleOrigin = bundleOrigin
        initCallback = completionHandler

        _ = read()
    }

    func read() -> Data? {
        if lastModified != mostRecentlySeenModification || cache == nil {
            var modificationOccurred = false
            let readCla = EncryptedFileCla(for: fsLocation) { () throws in
                // Executed when the lock is obtained
                var fileData: Data!

                do {
                    let encryptedData = try Data(contentsOf: self.fsLocation)
                    fileData = try Crypto.main.transform(with: .decryption, data: encryptedData)
                } catch {
                    if error is CryptoError { throw error }

                    // Reading failed for some reason. Try to restore from the bundle.
                    // If this fails, that failure will be thrown to the caller.
                    fileData = try Data(contentsOf: self.bundleOrigin)
                    try self.write(data: fileData, completionHandler: nil)
                }

                modificationOccurred = self.cache != nil && self.cache != fileData
                self.cache = fileData
            }

            ClaQueue([readCla]).run { error in
                // Executed when the lock operation has completed
                guard error == nil else {
                    NSApp.presentError(error!)
                    return
                }

                self.mostRecentlySeenModification = self.lastModified
                DispatchQueue.main.async {
                    self.initCallback?()
                    if modificationOccurred {
                        self.externalUpdateOccurred?(self.cache!)
                    }

                    self.initCallback = nil
                }
            }
        }

        return cache
    }

    func write(data contents: Data, completionHandler: (() -> Void)?) throws {
        guard lastModified == mostRecentlySeenModification else {
            throw FileError.writingFile
        }

        let writeCla = EncryptedFileCla(for: fsLocation) { () throws in
            let encryptedData = try Crypto.main.transform(with: .encryption, data: contents)
            try encryptedData.write(to: self.fsLocation)
            self.mostRecentlySeenModification = self.lastModified

            self.cache = contents
        }

        ClaQueue([writeCla]).run { error in
            guard error == nil else {
                NSApp.presentError(error!)
                return
            }

            DispatchQueue.main.async {
                completionHandler?()
            }
        }
    }

    func reset() {
        try? FileManager.default.removeItem(at: fsLocation)
    }
}
