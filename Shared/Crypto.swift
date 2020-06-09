//
//  Crypto.swift
//  shutup
//
//  Created by Ricky Romero on 10/14/19.
//  Copyright © 2019 Ricky Romero. All rights reserved.
//

import Foundation
import Cocoa

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
        queryBase[kSecAttrKeyType]       = constants["type"]!
        queryBase[kSecAttrKeySizeInBits] = constants["bits"]!
    }
    static var main = Crypto()

    let constants: [String: Any] = [
        "accessGroup":  Info.groupId,
        "type":         kSecAttrKeyTypeRSA,
        "bits":         3072,
        "label":        "Shut Up Encryption Key"
    ]
    var queryBase: [CFString: Any] = [
        kSecClass:     kSecClassKey,
        kSecReturnRef: true
    ]

    func requestKeychainUnlock() throws {
        var keychainStatus = SecKeychainStatus()
        SecKeychainGetStatus(nil, &keychainStatus)
        let keychainAccessible =
            (keychainStatus & kSecUnlockStateStatus) > 0 &&
            (keychainStatus & kSecReadPermStatus) > 0 &&
            (keychainStatus & kSecWritePermStatus) > 0

        if !keychainAccessible {
            let result = SecKeychainUnlock(nil, 0, nil, false)
            if result != errSecSuccess {
                throw CryptoError.accessingKeychain
            }
        }
    }

    var requiredKeysPresent: Bool {
        ![
            try? Crypto.main.lookupKey(.private),
            try? Crypto.main.lookupKey(.public)
        ].contains(nil)
    }

    var preCatalinaKeysPresent: Bool {
        ![
            try? Crypto.main.lookupKey(.private, requiringCatalinaMigration: true),
            try? Crypto.main.lookupKey(.public, requiringCatalinaMigration: true)
        ].contains(nil)
    }

    func clear() throws {
        try clear(preCatalinaItems: false)
    }

    func clear(preCatalinaItems: Bool) throws {
        let keyTags = [
            (constants["accessGroup"] as! String + ".public").data(using: .utf8)!,
            (constants["accessGroup"] as! String + ".private").data(using: .utf8)!
        ]
return
        // Invalidate keys by deleting them
//        for tag in keyTags {
//            if #available(macOS 10.15, *) {
//                if preCatalinaItems {
//                    query[kSecUseDataProtectionKeychain] = false
//                }
//            }
//
//            let result = SecItemDelete(query as CFDictionary)
//            guard [errSecSuccess, errSecItemNotFound].contains(result) else {
//                print("Failed to remove key.")
//                print(SecCopyErrorMessageString(result, nil)!)
//                throw CryptoError.removingInvalidKeys
//            }
//            if (result == errSecSuccess) {
//                print("Removed key successfully.")
//            }
//            if (result == errSecItemNotFound) {
//                print("No key found to remove.")
//            }
//        }
    }

    func generateKeyPair() throws {
        try clear()

        let keyId = UUID()
        var attributes = [
            kSecAttrKeyType:          constants["type"]!,
            kSecAttrKeySizeInBits:    constants["bits"]!,
            kSecAttrLabel:            "\(constants["label"]!)-\(keyId   )",
            kSecAttrIsPermanent:      true,
            kSecPrivateKeyAttrs:      [
                kSecAttrApplicationTag:   (constants["accessGroup"] as! String + ".private").data(using: .utf8)!
            ],
            kSecPublicKeyAttrs:      [
                kSecAttrApplicationTag:   (constants["accessGroup"] as! String + ".public").data(using: .utf8)!
            ]
        ]
//        if #available(macOS 10.15, *) {
//            attributes[kSecUseDataProtectionKeychain] = true
//        } else {
            attributes[kSecAttrSynchronizable] = true
//        }

        var error: Unmanaged<CFError>?
        guard SecKeyCreateRandomKey(attributes as CFDictionary, &error) != nil else {
            print("Failed to create key")
            throw CryptoError.generatingKeys
        }
    }

    func lookupKey(_ keyClass: KeyClass) throws -> SecKey {
        return try lookupKey(keyClass, requiringCatalinaMigration: false)
    }

    func lookupKey(_ keyClass: KeyClass, requiringCatalinaMigration: Bool) throws -> SecKey {
        var keyClassConstant = "" as CFString
        switch keyClass {
            case .private: keyClassConstant = kSecAttrKeyClassPrivate
            case .public: keyClassConstant = kSecAttrKeyClassPublic
        }

        var query: [CFString: Any] = [
            kSecClass: kSecClassKey,
            kSecMatchLimit: kSecMatchLimitAll,
            kSecAttrAccessGroup: Info.groupId,
            kSecAttrKeyClass: keyClassConstant,
            kSecReturnAttributes: true,
            kSecReturnData: true,
        ]
        if #available(macOS 10.15, *) {
            if requiringCatalinaMigration {
                query[kSecAttrSynchronizable] = true
            } else {
                query[kSecUseDataProtectionKeychain] = true
            }
        } else {
            query[kSecAttrSynchronizable] = true
        }

        // Query the keychain
        var rawCopyResult: CFTypeRef? = nil
        let copyStatus = SecItemCopyMatching(query as CFDictionary, &rawCopyResult)
        guard copyStatus == errSecSuccess else {
            print("Human-readable error:", SecCopyErrorMessageString(copyStatus, nil) ?? "")
            throw CryptoError.fetchingKeys
        }

        // Iterate through the results
        let resultList = rawCopyResult! as! [[CFString: Any]]
        for info in resultList {
            guard let accessGroup = info[kSecAttrAccessGroup] else { continue }
            guard accessGroup as! String == Info.groupId else { continue }
            guard let resultClass = (info[kSecAttrKeyClass] as! CFString?) else { continue }
            guard String(describing: resultClass) == String(describing: keyClassConstant) else { continue }
            guard let keyData = (info[kSecValueData] as! CFData?) else { continue }

            // We have a match. Turn it into a SecKey we can use.
            // (Irritatingly, "synchronizable" keys don't give you SecKey objects...)
            let matchedKeyAttributes: [CFString: Any] = [
                kSecClass: kSecClassKey,
                kSecAttrKeyClass: keyClassConstant,
                kSecAttrKeyType: constants["type"]!,
                kSecAttrKeySizeInBits: constants["bits"]!,
            ]

            var secKeyError: Unmanaged<CFError>? = nil
            guard let key = SecKeyCreateWithData(keyData, matchedKeyAttributes as CFDictionary, &secKeyError) else {
                print(secKeyError!.takeUnretainedValue() as Error)
                throw CryptoError.fetchingKeys
            }

            return key
        }

        // If we get to this point, there are no matches.
        throw CryptoError.fetchingKeys
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

        var transformError: Unmanaged<CFError>? = nil
        let transformed = secTransformFunc(key, .rsaEncryptionOAEPSHA512AESGCM, data as CFData, &transformError)

        guard transformError == nil else {
            print(transformError!.takeUnretainedValue() as Error)
            throw CryptoError.transformingData
        }

        guard transformed != nil else {
            throw CryptoError.transformingData
        }

        return transformed! as Data
    }
}

// MARK: Catalina migration

extension Crypto {
    func migratePreCatalinaKeys() throws {
        guard #available(macOS 10.15, *) else { return }

        // Migration is a two-step process: add the data protection flag,
        // then remove the sync flag. It fails if you try to do both in one step.
        var query: [CFString: Any] = [
            kSecClass: kSecClassKey,
            kSecMatchLimit: kSecMatchLimitAll,
            kSecAttrAccessGroup: Info.groupId,
            kSecAttrSynchronizable: true,
        ]
        var updates: [CFString: Any] = [
            kSecUseDataProtectionKeychain: true,
        ]

        // Add the data protection flag to the keys.
        let migrationResult = SecItemUpdate(query as CFDictionary, updates as CFDictionary)
        guard migrationResult == errSecSuccess else {
            print("Human-readable error:", SecCopyErrorMessageString(migrationResult, nil) ?? "")
            throw CryptoError.migratingPreCatalinaKeys
        }

        query[kSecUseDataProtectionKeychain] = true
        updates[kSecAttrSynchronizable] = false
        updates.removeValue(forKey: kSecUseDataProtectionKeychain)

        // Remove the sync flag from the keys.
        let syncRemovalResult = SecItemUpdate(query as CFDictionary, updates as CFDictionary)
        guard syncRemovalResult == errSecSuccess else {
            print("Human-readable error:", SecCopyErrorMessageString(syncRemovalResult, nil) ?? "")
            throw CryptoError.migratingPreCatalinaKeys
        }
    }
}
