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
            case .ok: buttonText = String(localized: "OK", comment: "Default button text – error recovery")
            case .quit: buttonText = String(localized: "Quit", comment: "Quitting app button text – error recovery")
            case .reset: buttonText = String(localized: "Reset Shut Up", comment: "Resetting app button text – error recovery")
            case .tryAgain: buttonText = String(localized: "Try Again…", comment: "Retrying button text – error recovery")
        }

        return NSLocalizedString(buttonText, comment: rawValue)
    }
}

struct MessageContents {
    let title: String?
    let info: String?
    let options: [RecoveryOption]?
}

class MessagingError: NSError, @unchecked Sendable {
    let cause: Error

    init(_ cause: Error) {
        self.cause = cause
        super.init(domain: Info.bundleId, code: -1, userInfo: [:])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func genAlertContents(_ contents: MessageContents) -> [String: Any] {
        var userInfo: [String: Any] = [:]

        if let title = contents.title, let info = contents.info {
            userInfo[NSLocalizedDescriptionKey] =
                NSLocalizedString(title, comment: "localizedErrorDescription")
            userInfo[NSLocalizedRecoverySuggestionErrorKey] =
                NSLocalizedString(info, comment: "localizedErrorRecoverSuggestion")
        }

        if let options = contents.options {
            userInfo[NSLocalizedRecoveryOptionsErrorKey] = options
        }

        return userInfo
    }

    override var userInfo: [String: Any] {
        var title: String?
        var info: String?
        var options: [RecoveryOption]?

        if cause is CryptoError {
            switch cause as! CryptoError {
                case .accessingKeychain:
                    title = String(localized: "Keychain locked or unavailable", comment: "CryptoError.accessingKeychain – title")
                    info = String(localized: "Shut Up requires keychain privileges to secure its data. Unlock your keychain to proceed.", comment: "CryptoError.accessingKeychain – info")
                    options = [.quit, .tryAgain]
                case .removingInvalidKeys:
                    title = String(localized: "Failed to remove invalid keys", comment: "CryptoError.removingInvalidKeys – title")
                    info = String(localized: "If the issue persists, try restarting your Mac.", comment: "CryptoError.removingInvalidKeys – info")
                case .generatingKeys:
                    title = String(localized: "Failed to generate a required key", comment: "CryptoError.generatingKeys – title")
                    info = String(localized: "If the issue persists, try restarting your Mac.", comment: "CryptoError.generatingKeys – info")
                case .fetchingKeys:
                    title = String(localized: "Encryption keys missing or damaged", comment: "CryptoError.fetchingKeys – title")
                    info = String(localized: "Shut Up failed to decrypt some required data. You can fix this by resetting Shut Up, but your allowlist may be lost.", comment: "CryptoError.fetchingKeys – info")
                    options = [.quit, .reset]
                case .transformingData:
                    title = String(localized: "Stylesheet or allowlist damaged", comment: "CryptoError.transformingData – title")
                    info = String(localized: "Shut Up failed to decrypt some required data. You can fix this by resetting Shut Up, but your allowlist may be lost.", comment: "CryptoError.transformingData – info")
                    options = [.quit, .reset]
            }
        } else if cause is LockError {
            switch cause as! LockError {
                case .timedOut:
                    title = String(localized: "Internal error occurred", comment: "LockError.timedOut – title")
                    info = String(localized: "Shut Up encountered a problem and cannot recover. Please quit and restart Shut Up.", comment: "LockError.timedOut – info")
                    options = [.quit]
            }
        } else if cause is FileError {
            switch cause as! FileError {
                case .checkingFreeSpace:
                    title = String(localized: "Startup disk is too full to continue", comment: "FileError.checkingFreeSpace – title")
                    info = String(localized: "Quit Shut Up and delete any files you don’t need.", comment: "FileError.checkingFreeSpace – info")
                    options = [.quit]
                case .readingFile:
                    title = String(localized: "Failed to read an internal file", comment: "FileError.readingFile – title")
                    info = String(localized: "Shut Up failed to read from an internal file. If this issue persists, please quit and restart Shut Up.", comment: "FileError.readingFile – info")
                case .writingFile:
                    title = String(localized: "Failed to write an internal file", comment: "FileError.writingFile – title")
                    info = String(localized: "Shut Up failed to write to an internal file. If this issue persists, please quit and restart Shut Up.", comment: "FileError.writingFile – info")
            }
        } else if cause is BrowserError {
            switch cause as! BrowserError {
                case .providingBlockRules:
                    title = String(localized: "Safari failed to read Shut Up’s content-blocking rules", comment: "BrowserError.providingBlockRules – title")
                    info = String(localized: "Shut Up sent Safari new content-blocking rules, but it failed. Try restarting Safari. If the issue persists, try restarting your Mac.", comment: "BrowserError.providingBlockRules – info")
                case .showingSafariPreferences:
                    title = String(localized: "Safari failed to open its settings", comment: "BrowserError.showingSafariPreferences – title")
                    info = String(localized: "Shut Up asked Safari to open its settings window, but it failed. Try opening Safari’s settings manually, then go to the “Extensions” section.", comment: "BrowserError.showingSafariPreferences – info")
                case .requestingExtensionStatus:
                    title = String(localized: "Safari failed to provide extension info", comment: "BrowserError.requestingExtensionStatus – title")
                    info = String(localized: "Shut Up asked Safari if its extensions are enabled, but it failed. Try quitting Shut Up and moving it to your Applications folder.\n\nIf the issue persists, try uninstalling Shut Up, restarting your Mac, and reinstalling Shut Up.", comment: "BrowserError.requestingExtensionStatus – info")
            }
        } else if cause is MiscError {
            switch cause as! MiscError {
                case .unexpectedNetworkResponse:
                    title = String(localized: "Unexpected response from rickyromero.com", comment: "MiscError.unexpectedNetworkResponse – title")
                    info = String(localized: "Shut Up tried to update the stylesheet, but the response the server sent was invalid. Try again later.", comment: "MiscError.unexpectedNetworkResponse – info")
            }
        } else if cause is URLError {
            title = String(localized: "Cannot connect to rickyromero.com", comment: "URLError – title")
            info = cause.localizedDescription
        }

        return genAlertContents(MessageContents(title: title, info: info, options: options?.reversed()))
    }
}
