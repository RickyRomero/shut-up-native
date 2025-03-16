//
//  DelegatingRecoverableError.swift
//  Shut Up
//
//  Created by Ricky Romero on 5/24/20.
//  See LICENSE.md for license information.
//

import Foundation

protocol ErrorRecoveryDelegate: AnyObject {
    func attemptRecovery(from error: Error, with option: RecoveryOption) -> Bool
}

struct DelegatingRecoverableError<Delegate, Error>: RecoverableError
    where Delegate: ErrorRecoveryDelegate, Error: Swift.Error
{
    let error: Error
    weak var delegate: Delegate?

    init(recoveringFrom error: Error, with delegate: Delegate?) {
        self.error = error
        self.delegate = delegate
    }

    private var recoveryActions: [RecoveryOption] {
        (
            (error as NSError)
                .userInfo[NSLocalizedRecoveryOptionsErrorKey] as? [RecoveryOption]
        ) ?? [.okay]
    }

    var recoveryOptions: [String] { recoveryActions.map { "\($0)" } }

    func attemptRecovery(optionIndex recoveryOptionIndex: Int) -> Bool {
        let action = recoveryActions[recoveryOptionIndex]

        return delegate?.attemptRecovery(from: error, with: action) ?? false
    }
}

extension DelegatingRecoverableError: LocalizedError {
    var errorDescription: String? {
        (error as NSError).userInfo[NSLocalizedDescriptionKey] as? String
    }

    var failureReason: String? {
        (error as NSError).userInfo[NSLocalizedFailureReasonErrorKey] as? String
    }

    var helpAnchor: String? {
        (error as NSError).userInfo[NSHelpAnchorErrorKey] as? String
    }

    var recoverySuggestion: String? {
        (error as NSError).userInfo[NSLocalizedRecoverySuggestionErrorKey] as? String
    }
}
