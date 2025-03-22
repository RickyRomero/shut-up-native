//
//  Crypto.swift
//  shutup
//
//  Created by Ricky Romero on 10/14/19.
//  See LICENSE.md for license information.
//

import Cocoa
import Foundation
import OSLog

private let logger = Logger(subsystem: Info.containingBundleId, category: "Crypto")

enum CryptoOperation {
    case encryption
    case decryption
}

enum KeyClass {
    case `private`
    case `public`
}

final class Crypto {
    private init() {
        // swiftformat:disable:next consecutiveSpaces
        queryBase[kSecAttrKeyType]       = constants["type"]!
        queryBase[kSecAttrKeySizeInBits] = constants["bits"]!
    }

    static var main = Crypto()
    let lock = LockFile(url: Info.containerUrl.appendingPathComponent("keychain.lock"))
    let queue = DispatchQueue(label: "\(Info.bundleId).keychain")

    private let constants: [String: Any] = [
        // swiftformat:disable consecutiveSpaces; swiftlint:disable colon
        "accessGroup":  Info.groupId,
        "type":         kSecAttrKeyTypeRSA,
        "bits":         3072,
        "label":        "Shut Up Encryption Key"
        // swiftformat:enable consecutiveSpaces; swiftlint:enable colon
    ]
    private var queryBase: [CFString: Any] = [
        // swiftformat:disable:next consecutiveSpaces, swiftlint:disable:next colon
        kSecClass:     kSecClassKey,
        kSecReturnRef: true
    ]

    private var setupStarted = false
    func bootstrap() {
        guard !setupStarted else { return }
        defer { self.lock.unlock() }
        setupStarted = true

        if !requiredKeysPresent {
            lock.claim()
            do {
                if !Crypto.main.requiredKeysPresent {
                    try Crypto.main.generateKeyPair()
                }
            } catch {
                DispatchQueue.main.async { showError(error) }
            }
        }
    }

    var requiredKeysPresent: Bool {
        ![
            try? Crypto.main.lookupKey(.private),
            try? Crypto.main.lookupKey(.public)
        ].contains(nil)
    }

    func clear() throws {
        // Invalidate keys by deleting them
        let query: [CFString: Any] = [
            kSecUseDataProtectionKeychain: true,
            kSecClass: kSecClassKey,
            kSecMatchLimit: kSecMatchLimitAll
        ]

        let result = SecItemDelete(query as CFDictionary)
        guard [errSecSuccess, errSecItemNotFound].contains(result) else {
            logger.error("Failed to remove key(s). Error: \(String(describing: SecCopyErrorMessageString(result, nil)))")
            throw CryptoError.removingInvalidKeys
        }
        if result == errSecSuccess {
            logger.info("Removed key(s) successfully.")
        }
        if result == errSecItemNotFound {
            logger.info("No key(s) found to remove.")
        }
    }

    func generateKeyPair() throws {
        try clear()

        let keyId = UUID()
        guard let accessGroup = constants["accessGroup"] as? String else {
            logger.error("Missing or invalid accessGroup. Shutting down.")
            throw CryptoError.generatingKeys
        }
        let attributes = [
            // swiftformat:disable consecutiveSpaces; swiftlint:disable colon
            kSecUseDataProtectionKeychain: true,
            kSecAttrKeyType:               constants["type"]!,
            kSecAttrKeySizeInBits:         constants["bits"]!,
            kSecAttrLabel:                 "\(constants["label"]!)-\(keyId)",
            kSecAttrIsPermanent:           true,
            kSecAttrSynchronizable:        false,
            kSecPrivateKeyAttrs: [
                kSecAttrApplicationTag: (accessGroup + ".private").data(using: .utf8)!,
                kSecAttrAccessible:     kSecAttrAccessibleAfterFirstUnlock
            ],
            kSecPublicKeyAttrs: [
                kSecAttrApplicationTag: (accessGroup + ".public").data(using: .utf8)!,
                kSecAttrAccessible:     kSecAttrAccessibleAfterFirstUnlock
            ]
            // swiftformat:enable consecutiveSpaces; swiftlint:enable colon
        ]

        var error: Unmanaged<CFError>?
        guard SecKeyCreateRandomKey(attributes as CFDictionary, &error) != nil else {
            logger.error("Failed to create key")
            throw CryptoError.generatingKeys
        }
    }

    func lookupKey(_ keyClass: KeyClass) throws -> SecKey {
        let keyClassConstant: CFString = switch keyClass {
        case .private:
            kSecAttrKeyClassPrivate
        case .public:
            kSecAttrKeyClassPublic
        }

        let query: [CFString: Any] = [
            kSecUseDataProtectionKeychain: true,
            kSecClass: kSecClassKey,
            kSecMatchLimit: kSecMatchLimitOne,
            kSecAttrAccessGroup: Info.groupId,
            kSecAttrKeyClass: keyClassConstant,
            kSecReturnRef: true
        ]

        var rawCopyResult: CFTypeRef?
        let copyStatus = SecItemCopyMatching(query as CFDictionary, &rawCopyResult)
        guard copyStatus == errSecSuccess else {
            logger.error("Human-readable error: \(String(describing: SecCopyErrorMessageString(copyStatus, nil) ?? "" as CFString))")
            throw CryptoError.fetchingKeys
        }

        guard let raw = rawCopyResult else {
            throw CryptoError.fetchingKeys
        }
        guard CFGetTypeID(raw) == SecKeyGetTypeID() else {
            throw CryptoError.fetchingKeys
        }
        return unsafeBitCast(raw, to: SecKey.self)
    }

    func transform(with operation: CryptoOperation, data: Data) throws -> Data {
        let key: SecKey!
        let keyClass: KeyClass!
        let secTransformFunc: (
            (
                _: SecKey,
                _: SecKeyAlgorithm,
                _: CFData,
                _: UnsafeMutablePointer<Unmanaged<CFError>?>?
            ) -> CFData?
        )!
        switch operation {
        case .encryption: keyClass = .public; secTransformFunc = SecKeyCreateEncryptedData
        case .decryption: keyClass = .private; secTransformFunc = SecKeyCreateDecryptedData
        }
        key = try lookupKey(keyClass)

        var transformError: Unmanaged<CFError>?
        let transformed = secTransformFunc(key, .rsaEncryptionOAEPSHA512AESGCM, data as CFData, &transformError)

        if (transformError?.takeUnretainedValue()) != nil {
            throw CryptoError.transformingData
        }

        guard let result = transformed else {
            throw CryptoError.transformingData
        }

        return result as Data
    }
}
