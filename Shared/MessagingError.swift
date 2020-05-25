//
//  MessagingError.swift
//  shutup
//
//  Created by Ricky Romero on 5/21/20.
//  Copyright © 2020 Ricky Romero. All rights reserved.
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
    case providingBlocklist
    case showingSafariPreferences
    case requestingExtensionStatus
}

enum NetworkingError: Error {
    case accessingNetwork
    case resolvingDns
    case contactingServer
    case interpretingResponse
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

        return NSLocalizedString(buttonText, comment: self.rawValue)
    }
}

struct MessageContents {
    let title: String?
    let info: String?
    let options: [RecoveryOption]?
}

class MessagingError: NSError {
    let cause: Error

    init(_ cause: Error) {
        self.cause = cause
        super.init(domain: Info.bundleId, code: -1, userInfo: [:])
    }
    
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
                    info = "Shut Up failed to decrypt some required data. You can fix this by resetting Shut Up, but your whitelist may be lost."
                    options = [.quit, .reset]
                case .transformingData:
                    title = "Stylesheet or whitelist damaged"
                    info = "Shut Up failed to decrypt some required data. You can fix this by resetting Shut Up, but your whitelist may be lost."
                    options = [.quit, .reset]
            }
        } else if cause is LockError {
            switch cause as! LockError {
                case .timedOut:
                    title = "Internal error occurred"
                    info = "Shut Up encountered a problem and cannot recover. Please quit and restart Shut Up."
                    options = [.quit]
            }
        } else if cause is FileError {
            switch cause as! FileError {
                case .checkingFreeSpace:
                    title = "Startup disk is too full to continue"
                    info = "Quit Shut Up and delete any files you don't need."
                    options = [.quit]
                case .readingFile:
                    title = "Example Error"
                    info = "Example Info"
                case .writingFile:
                    title = "Example Error"
                    info = "Example Info"
            }
        } else if cause is BrowserError {
            switch cause as! BrowserError {
                case .providingBlocklist:
                    title = "Safari failed to read Shut Up's blocklist"
                    info = "Shut Up sent Safari a new blocklist, but it failed. Try restarting Safari. If the issue persists, try restarting your Mac."
                case .showingSafariPreferences:
                    title = "Safari failed to open its preferences"
                    info = "Shut Up asked Safari to open its preferences window, but it failed. Try opening Safari's preferences manually, then go to the “Extensions” section."
                case .requestingExtensionStatus:
                    title = "Safari failed to provide extension info"
                    info = "Shut Up asked Safari if its extensions are enabled, but it failed. Try opening Safari's preferences manually, then go to the “Extensions” section to check the status.\n\nIf the issue persists, try restarting your Mac."
            }
        } else if cause is NetworkingError {
            switch cause as! NetworkingError {
                case .accessingNetwork:
                    title = "No network connection"
                    info = "Your Mac appears to be offline. Stylesheet updates require an active Internet connection."
                case .resolvingDns: fallthrough
                case .contactingServer:
                    title = "Cannot connect to rickyromero.com"
                    info = "Check your Internet connection or try again later."
                case .interpretingResponse:
                    title = "Unexpected response received"
                    info = "Shut Up got an unexpected response when connecting to rickyromero.com. Check your Internet connection or try again later."
            }
        }

        return genAlertContents(MessageContents(title: title, info: info, options: options?.reversed()))
    }
}
