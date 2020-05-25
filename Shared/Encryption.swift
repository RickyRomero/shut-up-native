//
//  Encryption.swift
//  shutup
//
//  Created by Ricky Romero on 10/14/19.
//  Copyright © 2019 Ricky Romero. All rights reserved.
//


// https://github.com/satispay/in-store-api-swift-sdk/blob/master/SatispayInStore/Crypto/RSA.swift

import Foundation

enum EncError: Error {
    case message(String)
}

struct Crypto {
    private init() {}
    static let shared = Crypto()

    static let lockUrl = Info.containerUrl.appendingPathComponent("keychain.lock")
    static let secureFiles = [
        Info.blocklistUrl,
        Info.whitelistUrl
    ]
    static let key: [String: Any] = [
        "accessGroup":  Info.groupId,
        "type":         kSecAttrKeyTypeRSA,
        "bits":         3072,
        "label":        "Shut Up Encryption Key"
    ]
    static let queryBase: [String: Any] = [
        kSecClass as String:                kSecClassKey,
        kSecReturnRef as String:            true,
        kSecAttrKeyType as String:          Crypto.key["type"]!,
        kSecAttrKeySizeInBits as String:    Crypto.key["bits"]!,
        kSecAttrAccessGroup as String:      Crypto.key["accessGroup"] as! String
    ]

    static var instanceCount = 0
    static func incrementInstanceCount() {
        instanceCount += 1
        print("instanceCount is now \(instanceCount).")
    }

    static func lockOps() throws {
        let lockExpires: Double = 1000 * 60 * 5 // 5 minutes
        let lockSecured = FileManager.default.createFile(
            atPath: Crypto.lockUrl.path,
            contents: Data(), attributes: [.immutable: 1]
        )

        if !lockSecured {
            do {
                let attributes = try FileManager.default.attributesOfItem(atPath: Crypto.lockUrl.path)
                let lockAge = Date().timeIntervalSince1970 - (attributes[.creationDate]! as! Date).timeIntervalSince1970

                if lockAge > lockExpires {
                    print("Lock expired. Trying to recreate...")
                    try unlockOps()
                    try lockOps()
                } else {
                    print("Can't continue.")
                    throw EncError.message("Lock unavailable.")
                }
            } catch {
                print(error.localizedDescription)
                throw error
            }
        }
    }

    static func unlockOps() throws {
        do {
            try FileManager.default.setAttributes([.immutable: 0], ofItemAtPath: Crypto.lockUrl.path)
            try FileManager.default.removeItem(at: Crypto.lockUrl)
        } catch {
            print(error.localizedDescription)
            throw error
        }
    }

    static func generateKeyPair() throws {
        Crypto.reset()

        let attributes: [String: Any] = [
            kSecAttrKeyType as String:          Crypto.key["type"]!,
            kSecAttrKeySizeInBits as String:    Crypto.key["bits"]!,
            kSecPrivateKeyAttrs as String:      [
                kSecAttrIsPermanent as String:      true,
                kSecAttrLabel as String:            Crypto.key["label"]!,
                kSecAttrAccessGroup as String:      Crypto.key["accessGroup"] as! String,
                kSecAttrApplicationTag as String:   (Crypto.key["accessGroup"] as! String + ".private").data(using: .utf8)!,
                kSecAttrSynchronizable as String:   false
            ],
            kSecPublicKeyAttrs as String:      [
                kSecAttrIsPermanent as String:      true,
                kSecAttrLabel as String:            Crypto.key["label"]!,
                kSecAttrAccessGroup as String:      Crypto.key["accessGroup"] as! String,
                kSecAttrApplicationTag as String:   (Crypto.key["accessGroup"] as! String + ".public").data(using: .utf8)!,
                kSecAttrSynchronizable as String:   false
            ]
        ]

        var error: Unmanaged<CFError>?
        guard SecKeyCreateRandomKey(attributes as CFDictionary, &error) != nil else {
            throw error!.takeRetainedValue() as Error
        }
    }

    static func lookupKey(_ type: String) -> SecKey? {
        var query = queryBase
        query[kSecAttrApplicationTag as String] = (Crypto.key["accessGroup"] as! String + "." + type).data(using: .utf8)!

        print("Querying keychain........")
        var result: CFTypeRef? = nil
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        print("Load status (NO ERROR YET): ", status)
        
        return result as! SecKey?
    }

    static func reset() {
        let keyTags = [
            (Crypto.key["accessGroup"] as! String + ".public").data(using: .utf8)!,
            (Crypto.key["accessGroup"] as! String + ".private").data(using: .utf8)!
        ]

        // Invalidate keys by deleting them
        for tag in keyTags {
            var query = queryBase
            query[kSecAttrApplicationTag as String] = tag

            let result = SecItemDelete(query as CFDictionary)
            
            dump(result)
            guard result == errSecSuccess else {
                print("Failed to remove key.")
                print(SecCopyErrorMessageString(result, nil)!)
                return
            }
        }
    }

    static func encrypt(_ inputData: Data) throws -> Data {
        let key = lookupKey("public")!

        var transformError: Unmanaged<CFError>?
        let transform = SecEncryptTransformCreate(key, &transformError)

        guard transformError == nil else {
            throw transformError!.takeRetainedValue() as Error
        }

        var attributeError: Unmanaged<CFError>?
        guard SecTransformSetAttribute(transform, kSecTransformInputAttributeName, inputData as CFTypeRef, &attributeError) else {
            throw attributeError!.takeRetainedValue() as Error
        }

        let transformAttrs: CFDictionary = SecTransformCopyExternalRepresentation(transform)
        dump(transformAttrs)

        var encryptionError: Unmanaged<CFError>?
        guard let encryptedData = SecTransformExecute(transform, &encryptionError) as? Data else {
            throw encryptionError!.takeRetainedValue() as Error
        }

        return encryptedData
    }

    static func decrypt(_ inputData: Data) throws -> Data {
        let key = lookupKey("private")!
        
        var transformError: Unmanaged<CFError>?
        let transform = SecDecryptTransformCreate(key, &transformError)
        
        guard transformError == nil else {
            throw transformError!.takeRetainedValue() as Error
        }
        
        var attributeError: Unmanaged<CFError>?
        guard SecTransformSetAttribute(transform, kSecTransformInputAttributeName, inputData as CFTypeRef, &attributeError) else {
            throw attributeError!.takeRetainedValue() as Error
        }
        
        var decryptionError: Unmanaged<CFError>?
        print("Decrypting...")
        guard let decryptedData = SecTransformExecute(transform, &decryptionError) as? Data else {
            throw decryptionError!.takeRetainedValue() as Error
        }
        print("Decrypted.")

        return decryptedData
    }
}
