//
//  EncryptedFile.swift
//  shutup
//
//  Created by Ricky Romero on 5/13/20.
//  See LICENSE.md for license information.
//

import Cocoa

final class EncryptedFile {
    let fsLocation: URL
    let bundleOrigin: URL

    var mostRecentlySeenModification: Date?
    var lastModified: Date? {
        let attributes = try? FileManager.default.attributesOfItem(atPath: self.fsLocation.path)
        return attributes?[.modificationDate] as? Date
    }

    var cache: Data?
    var externalUpdateOccurred: ((Data) -> Void)?
    var initCallback: (() -> Void)?

    var lock: LockFile!
    let queue: DispatchQueue!

    init(fsLocation: URL, bundleOrigin: URL) {
        self.fsLocation = fsLocation
        self.bundleOrigin = bundleOrigin

        self.lock = LockFile(url: fsLocation.appendingPathExtension("lock"))
        self.queue = DispatchQueue(label: "\(Info.bundleId).\(fsLocation.lastPathComponent)")

        self.queue.sync { _ = self.read() }
    }

    func keysVerifiedPresent() -> Bool {
        return Crypto.main.requiredKeysPresent
    }

    func read(force: Bool = false) -> Data? {
        if force { self.cache = nil }

        if self.lastModified != self.mostRecentlySeenModification || self.cache == nil {
            defer { self.lock.unlock() }
            var modificationOccurred = false

            do {
                let keysPresent = self.keysVerifiedPresent()
                if keysPresent {
                    self.lock.claim()

                    var fileData: Data!

                    do {
                        let encryptedData = try Data(contentsOf: self.fsLocation)
                        fileData = try Crypto.main.transform(with: .decryption, data: encryptedData)
                    } catch {
                        if error is CryptoError { throw error }

                        // Reading failed for some reason. Try to restore from the bundle.
                        // If this fails, that failure will be thrown to the caller.
                        fileData = try Data(contentsOf: self.bundleOrigin)
                        try self.write(data: fileData)
                    }

                    modificationOccurred = self.cache != nil && self.cache != fileData
                    self.cache = fileData

                    self.mostRecentlySeenModification = self.lastModified
                }
            } catch {
                DispatchQueue.main.async { showError(error) }
            }

            DispatchQueue.main.async {
                self.initCallback?()
                if modificationOccurred {
                    self.externalUpdateOccurred?(self.cache!)
                }

                self.initCallback = nil
            }
        }

        return self.cache
    }

    func write(data contents: Data) throws {
        guard self.lastModified == self.mostRecentlySeenModification else {
            throw FileError.writingFile
        }
        defer { self.lock.unlock() }

        do {
            let keysPresent = self.keysVerifiedPresent()

            if keysPresent {
                self.lock.claim()

                let encryptedData = try Crypto.main.transform(with: .encryption, data: contents)
                try encryptedData.write(to: self.fsLocation)
                self.mostRecentlySeenModification = self.lastModified

                self.cache = contents
            }
        } catch {
            DispatchQueue.main.async { showError(error) }
        }
    }

    func reset() {
        try? FileManager.default.removeItem(at: self.fsLocation)
    }
}
