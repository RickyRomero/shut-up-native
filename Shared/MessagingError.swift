//
//  MessagingError.swift
//  shutup
//
//  Created by Ricky Romero on 5/21/20.
//  See LICENSE.md for license information.
//

import Foundation

enum UnknownError: Error {
    case unknown
}

enum LockError: Error {
    case timedOut
}

enum CryptoError: Error {
    case accessingKeychain
    case removingInvalidKeys
    case generatingKeys
    case fetchingKeys
    case transformingData
    case migratingPreCatalinaKeys
}

enum FileError: Error {
    case checkingFreeSpace
    case readingFile
    case writingFile
}

enum BrowserError: Error {
    case providingBlockRules
    case showingSafariPreferences
    case requestingExtensionStatus
}

enum MiscError: Error {
    case unexpectedNetworkResponse
}

enum RecoveryOption: String, CaseIterable, CustomStringConvertible {
    case ok
    case quit
    case reset
    case tryAgain

    var description: String {
        var buttonText: String!
        switch self {
        case .ok: buttonText = "OK"
        case .quit: buttonText = "Quit"
        case .reset: buttonText = "Reset Shut Up"
        case .tryAgain: buttonText = "Try Again…"
        }

        return NSLocalizedString(buttonText, comment: rawValue)
    }
}

struct MessageContents {
    let title: String?
    let info: String?
    let options: [RecoveryOption]?
}

struct MessagingError: Error, LocalizedError, CustomNSError, Sendable {
    /// The underlying error that caused this MessagingError.
    let cause: Error

    /// Computes the title, information, and recovery options based on the underlying error.
    private var messageContents: MessageContents {
        var title: String?
        var info: String?
        var options: [RecoveryOption]?

        if let cryptoError = cause as? CryptoError {
            switch cryptoError {
            case .accessingKeychain:
                title = "Keychain locked or unavailable"
                info = "Shut Up requires keychain privileges to secure its data. Unlock your keychain to proceed."
                options = [.quit, .tryAgain]
            case .removingInvalidKeys:
                title = "Failed to remove invalid keys"
                info = "If the issue persists, try restarting your Mac."
            case .generatingKeys:
                title = "Failed to generate a required key"
                info = "If the issue persists, try restarting your Mac."
            case .fetchingKeys:
                title = "Encryption keys missing or damaged"
                info = "Shut Up failed to decrypt some required data. You can fix this by resetting Shut Up, but your allowlist may be lost."
                options = [.quit, .reset]
            case .transformingData:
                title = "Stylesheet or allowlist damaged"
                info = "Shut Up failed to decrypt some required data. You can fix this by resetting Shut Up, but your allowlist may be lost."
                options = [.quit, .reset]
            case .migratingPreCatalinaKeys:
                title = "Key migration failed"
                info = "Shut Up tried to migrate encryption keys from an older version of macOS, but it failed. You can fix this by resetting Shut Up, but your allowlist may be lost."
                options = [.quit, .reset]
            }
        } else if let lockError = cause as? LockError {
            switch lockError {
            case .timedOut:
                title = "Internal error occurred"
                info = "Shut Up encountered a problem and cannot recover. Please quit and restart Shut Up."
                options = [.quit]
            }
        } else if let fileError = cause as? FileError {
            switch fileError {
            case .checkingFreeSpace:
                title = "Startup disk is too full to continue"
                info = "Quit Shut Up and delete any files you don’t need."
                options = [.quit]
            case .readingFile:
                title = "Failed to read an internal file"
                info = "Shut Up failed to read from an internal file. If this issue persists, please quit and restart Shut Up."
            case .writingFile:
                title = "Failed to write an internal file"
                info = "Shut Up failed to write to an internal file. If this issue persists, please quit and restart Shut Up."
            }
        } else if let browserError = cause as? BrowserError {
            switch browserError {
            case .providingBlockRules:
                title = "Safari failed to read Shut Up’s content-blocking rules"
                info = "Shut Up sent Safari new content-blocking rules, but it failed. Try restarting Safari. If the issue persists, try restarting your Mac."
            case .showingSafariPreferences:
                title = "Safari failed to open its settings"
                info = "Shut Up asked Safari to open its settings window, but it failed. Try opening Safari’s settings manually, then go to the “Extensions” section."
            case .requestingExtensionStatus:
                title = "Safari failed to provide extension info"
                info = """
                Shut Up asked Safari if its extensions are enabled, but it failed. Try quitting Shut Up and moving it to your Applications folder.

                If the issue persists, try uninstalling Shut Up, restarting your Mac, and reinstalling Shut Up.
                """
            }
        } else if let miscError = cause as? MiscError {
            switch miscError {
            case .unexpectedNetworkResponse:
                title = "Unexpected response from rickyromero.com"
                info = "Shut Up tried to update the stylesheet, but the response the server sent was invalid. Try again later."
            }
        } else if let urlError = cause as? URLError {
            title = "Cannot connect to rickyromero.com"
            info = urlError.localizedDescription
        }

        // Reverse the order of options if needed (preserving your original behavior)
        return MessageContents(title: title, info: info, options: options?.reversed())
    }

    // MARK: - LocalizedError Conformance

    var errorDescription: String? {
        guard let title = messageContents.title else { return nil }
        return NSLocalizedString(title, comment: "localizedErrorDescription")
    }

    var recoverySuggestion: String? {
        guard let info = messageContents.info else { return nil }
        return NSLocalizedString(info, comment: "localizedErrorRecoverySuggestion")
    }

    // MARK: - CustomNSError Conformance

    static var errorDomain: String { "com.shutup.MessagingError" }

    var errorCode: Int { -1 }

    var errorUserInfo: [String: Any] {
        var userInfo: [String: Any] = [:]
        if let title = messageContents.title, let info = messageContents.info {
            userInfo[NSLocalizedDescriptionKey] = NSLocalizedString(title, comment: "localizedErrorDescription")
            userInfo[NSLocalizedRecoverySuggestionErrorKey] = NSLocalizedString(info, comment: "localizedErrorRecoverySuggestion")
        }
        if let options = messageContents.options {
            userInfo[NSLocalizedRecoveryOptionsErrorKey] = options.map { $0.description }
        }
        return userInfo
    }
}
