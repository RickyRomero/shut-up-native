//
//  Crypto.swift
//  shutup
//
//  Created by Ricky Romero on 10/14/19.
//  See LICENSE.md for license information.
//

import Cocoa
import Foundation

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
        // swiftformat:disable:next all
        queryBase[kSecAttrKeyType]       = constants["type"]!
        queryBase[kSecAttrKeySizeInBits] = constants["bits"]!
    }

    static var main = Crypto()
    let lock = LockFile(url: Info.containerUrl.appendingPathComponent("keychain.lock"))
    let queue = DispatchQueue(label: "\(Info.bundleId).keychain")

    private let constants: [String: Any] = [
        // swiftformat:disable all
        "accessGroup":  Info.groupId,
        "type":         kSecAttrKeyTypeRSA,
        "bits":         3072,
        "label":        "Shut Up Encryption Key"
        // swiftformat:enable all
    ]
    private var queryBase: [CFString: Any] = [
        // swiftformat:disable:next all
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
        var query: [CFString: Any] = [
            kSecClass: kSecClassKey,
            kSecMatchLimit: kSecMatchLimitAll
        ]

        query[kSecUseDataProtectionKeychain] = true

        let result = SecItemDelete(query as CFDictionary)
        guard [errSecSuccess, errSecItemNotFound].contains(result) else {
            print("Failed to remove key(s).")
            print(SecCopyErrorMessageString(result, nil)!)
            throw CryptoError.removingInvalidKeys
        }
        if result == errSecSuccess {
            print("Removed key(s) successfully.")
        }
        if result == errSecItemNotFound {
            print("No key(s) found to remove.")
        }
    }

    func generateKeyPair() throws {
        try clear()

        let keyId = UUID()
        var attributes = [
            // swiftformat:disable all
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
            // swiftformat:enable all
        ]
        attributes[kSecUseDataProtectionKeychain] = true

        var error: Unmanaged<CFError>?
        guard SecKeyCreateRandomKey(attributes as CFDictionary, &error) != nil else {
            print("Failed to create key")
            throw CryptoError.generatingKeys
        }
    }

    func lookupKey(_ keyClass: KeyClass) throws -> SecKey {
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
            kSecReturnData: true
        ]

        query[kSecUseDataProtectionKeychain] = true

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
                kSecAttrKeySizeInBits: constants["bits"]!
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
