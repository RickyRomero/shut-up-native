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

final class Crypto {
    private init() {
        queryBase[String(kSecAttrKeyType)]       = constants["type"]!
        queryBase[String(kSecAttrKeySizeInBits)] = constants["bits"]!
    }
    static var main = Crypto()

    let constants: [String: Any] = [
        "accessGroup":  Info.groupId,
        "type":         kSecAttrKeyTypeRSA,
        "bits":         3072,
        "label":        "Shut Up Encryption Key"
    ]
    var queryBase: [String: Any] = [
        String(kSecClass):     kSecClassKey,
        String(kSecReturnRef): true
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
            try? Crypto.main.lookupKey("private"),
            try? Crypto.main.lookupKey("public")
        ].contains(nil)
    }

    var preCatalinaKeysPresent: Bool {
        ![
            try? Crypto.main.lookupKey("private", requiringCatalinaMigration: true),
            try? Crypto.main.lookupKey("public", requiringCatalinaMigration: true)
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

        // Invalidate keys by deleting them
        for tag in keyTags {
            var query = queryBase
            query[String(kSecAttrApplicationTag)] = tag
            if #available(macOS 10.15, *) {
                if preCatalinaItems {
                    query[String(kSecUseDataProtectionKeychain)] = false
                }
            }

            let result = SecItemDelete(query as CFDictionary)
            guard [errSecSuccess, errSecItemNotFound].contains(result) else {
                print("Failed to remove key.")
                print(SecCopyErrorMessageString(result, nil)!)
                throw CryptoError.removingInvalidKeys
            }
            if (result == errSecSuccess) {
                print("Removed key successfully.")
            }
            if (result == errSecItemNotFound) {
                print("No key found to remove.")
            }
        }
    }

    func generateKeyPair() throws {
        try clear()

        var attributes: [String: Any] = [
            String(kSecAttrKeyType):          constants["type"]!,
            String(kSecAttrKeySizeInBits):    constants["bits"]!,
            String(kSecAttrLabel):            constants["label"]!,
            String(kSecAttrIsPermanent):      true,
            String(kSecAttrSynchronizable):   false,
            String(kSecPrivateKeyAttrs):      [
                String(kSecAttrApplicationTag):   (constants["accessGroup"] as! String + ".private").data(using: .utf8)!
            ],
            String(kSecPublicKeyAttrs):      [
                String(kSecAttrApplicationTag):   (constants["accessGroup"] as! String + ".public").data(using: .utf8)!
            ]
        ]
        if #available(macOS 10.15, *) {
            attributes[String(kSecUseDataProtectionKeychain)] = true
        }

        var error: Unmanaged<CFError>?
        guard SecKeyCreateRandomKey(attributes as CFDictionary, &error) != nil else {
            print("Failed to create key")
            _ = error!.takeRetainedValue() as Error
            throw CryptoError.generatingKeys
        }
    }

    func lookupKey(_ type: String) throws -> SecKey {
        return try lookupKey(type, requiringCatalinaMigration: false)
    }

    func lookupKey(_ type: String, requiringCatalinaMigration: Bool) throws -> SecKey {
        var query = queryBase
        query[String(kSecAttrApplicationTag)] = (constants["accessGroup"] as! String + "." + type).data(using: .utf8)!
        if #available(macOS 10.15, *) {
            if requiringCatalinaMigration {
                query[String(kSecUseDataProtectionKeychain)] = false
            }
        }

        print("Querying keychain........")
        var result: CFTypeRef? = nil
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        print("Load status (NO ERROR YET): ", status)
        print("Human-readable:", SecCopyErrorMessageString(status, nil) ?? "")
        print("Result for \(type) is nil?", result as! SecKey? == nil)

        if result as! SecKey? == nil {
            throw CryptoError.fetchingKeys
        }

        return result as! SecKey
    }

    func transform(with operation: CryptoOperation, data: Data) throws -> Data {
        let key: SecKey!
        let keyType: String!
        let secTransformFunc: (
            (
                _: SecKey,
                _: SecKeyAlgorithm,
                _: CFData,
                _: UnsafeMutablePointer<Unmanaged<CFError>?>?
            ) -> CFData?
        )!
        switch operation {
            case .encryption: keyType = "public"; secTransformFunc = SecKeyCreateEncryptedData
            case .decryption: keyType = "private"; secTransformFunc = SecKeyCreateDecryptedData
        }
        key = try lookupKey(keyType)

        var transformError: Unmanaged<CFError>? = nil
        let transformed = secTransformFunc(key, .rsaEncryptionOAEPSHA512AESGCM, data as CFData, &transformError)

        guard transformError == nil else {
            print(transformError!.takeRetainedValue() as Error)
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
        let keyTags = ["private", "public"]
//        let commonAttributes: [String: Any] = [
//            String(kSecClass):                     kSecClassKey,
//            String(kSecAttrKeyType):               constants["type"]!,
//            String(kSecAttrKeySizeInBits):         constants["bits"]!,
//            String(kSecAttrLabel):                 constants["label"]!,
//            String(kSecAttrIsPermanent):           true,
//            String(kSecAttrSynchronizable):        false,
//            String(kSecUseDataProtectionKeychain): true
//        ]
        let secondPause = UInt32(1)
        var exportedKeyAttributes: [[String: Any]] = []

        print("Querying keychain for old keys........")
        for tag in keyTags {
            let key = try lookupKey(tag, requiringCatalinaMigration: true)

//            usleep(1000 * 1000 * secondPause)
//            print("Exporting previous key...")
//            var exportError: Unmanaged<CFError>? = nil
//            let keyData = SecKeyCopyExternalRepresentation(key, &exportError)
//            guard exportError == nil && keyData != nil else {
//                print("Failed to export key...")
//                print(exportError!.takeRetainedValue() as Error)
//                throw CryptoError.migratingPreCatalinaKeys
//            }

            usleep(1000 * 1000 * 3)
            print("Retrieving key attributes...")
            let attributes = SecKeyCopyAttributes(key)
            guard attributes != nil else {
                print("Failed to retrieve attributes...")
                throw CryptoError.migratingPreCatalinaKeys
            }

            var updatedAttributes = attributes! as! [String: Any]
            updatedAttributes[String(kSecAttrApplicationTag)] = (constants["accessGroup"] as! String + tag).data(using: .utf8)!
            updatedAttributes[String(kSecUseDataProtectionKeychain)] = true

//            var updatedAttributes = commonAttributes
//            updatedAttributes[String(kSecAttrKeyClass)] = tag == "public" ? kSecAttrKeyClassPublic : kSecAttrKeyClassPrivate
//            updatedAttributes[String(kSecAttrApplicationTag)] = (constants["accessGroup"] as! String + tag).data(using: .utf8)!
//            updatedAttributes[String(kSecValueData)] = keyData!

            exportedKeyAttributes.append(updatedAttributes)

            usleep(1000 * 1000 * secondPause)
            print("Deleting previous key...")
            var query = queryBase
            query[String(kSecAttrApplicationTag)] = (constants["accessGroup"] as! String + "." + tag).data(using: .utf8)!

            let deleteResult = SecItemDelete(query as CFDictionary)
            guard [errSecSuccess, errSecItemNotFound].contains(deleteResult) else {
                print("Failed to remove key.")
                print(SecCopyErrorMessageString(deleteResult, nil)!)
                throw CryptoError.removingInvalidKeys
            }
            if (deleteResult == errSecSuccess) {
                print("Removed key successfully.")
            }
            if (deleteResult == errSecItemNotFound) {
                print("No key found to remove.")
            }
        }

        for updatedAttributes in exportedKeyAttributes {
            usleep(1000 * 1000 * secondPause)
            print("Importing migrated key...")
            var importResult: CFTypeRef? = nil
            let importStatus = SecItemAdd(updatedAttributes as CFDictionary, &importResult)
            guard importStatus == errSecSuccess else {
                print("Failed to import updated key...")
                print(SecCopyErrorMessageString(importStatus, nil)!)
                throw CryptoError.migratingPreCatalinaKeys
            }
            if importStatus == errSecSuccess {
                print("SUCCESS")
            }
        }
    }
}
