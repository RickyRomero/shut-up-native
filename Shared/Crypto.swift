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
        queryBase[kSecAttrKeyType as String]       = key["type"]!
        queryBase[kSecAttrKeySizeInBits as String] = key["bits"]!
        queryBase[kSecAttrAccessGroup as String]   = key["accessGroup"] as! String
    }
    static var main = Crypto()

    let key: [String: Any] = [
        "accessGroup":  Info.groupId,
        "type":         kSecAttrKeyTypeRSA,
        "bits":         3072,
        "label":        "Shut Up Encryption Key"
    ]
    var queryBase: [String: Any] = [
        kSecClass as String:     kSecClassKey,
        kSecReturnRef as String: true
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

    func clear() throws {
        let keyTags = [
            (key["accessGroup"] as! String + ".public").data(using: .utf8)!,
            (key["accessGroup"] as! String + ".private").data(using: .utf8)!
        ]

        // Invalidate keys by deleting them
        for tag in keyTags {
            var query = queryBase
            query[kSecAttrApplicationTag as String] = tag

            let result = SecItemDelete(query as CFDictionary)
            guard result == errSecSuccess || result == errSecItemNotFound else {
                print("Failed to remove key.")
                print(SecCopyErrorMessageString(result, nil)!)
                throw CryptoError.removingInvalidKeys
            }
        }
    }

    func generateKeyPair() throws {
        do { try clear() } catch { throw error }

        let attributes: [String: Any] = [
            kSecAttrKeyType as String:          key["type"]!,
            kSecAttrKeySizeInBits as String:    key["bits"]!,
            kSecAttrIsPermanent as String:      true,
            kSecAttrLabel as String:            key["label"]!,
            kSecAttrAccessGroup as String:      key["accessGroup"] as! String,
            kSecAttrSynchronizable as String:   false,
            kSecPrivateKeyAttrs as String:      [
                kSecAttrApplicationTag as String:   (key["accessGroup"] as! String + ".private").data(using: .utf8)!
            ],
            kSecPublicKeyAttrs as String:      [
                kSecAttrApplicationTag as String:   (key["accessGroup"] as! String + ".public").data(using: .utf8)!
            ]
        ]

        var error: Unmanaged<CFError>?
        guard SecKeyCreateRandomKey(attributes as CFDictionary, &error) != nil else {
            print("Failed to create key")
            _ = error!.takeRetainedValue() as Error
            throw CryptoError.generatingKeys
        }
    }

    func lookupKey(_ type: String) throws -> SecKey {
        var query = queryBase
        query[kSecAttrApplicationTag as String] = (key["accessGroup"] as! String + "." + type).data(using: .utf8)!

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
        do {
            key = try lookupKey(keyType)
        } catch {
            throw error
        }

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
