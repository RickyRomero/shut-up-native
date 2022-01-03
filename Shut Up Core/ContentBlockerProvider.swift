//
//  ContentBlockerProvider.swift
//  Shut Up Core
//
//  Created by Ricky Romero on 6/23/20.
//  See LICENSE.md for license information.
//

import Foundation

final class ContentBlockerProvider {
    func coalesce() -> [ContentBlockerRule] {
        let cssRules = Stylesheet.main.rules

        Whitelist.main.load(force: true)
        let whitelist = Whitelist.main.entries
        let wildcardDomains = whitelist.map { "*\($0)" }

        let rules = cssRules.map { cssRule -> [ContentBlockerRule] in
            cssRule.selectors.map { selector -> ContentBlockerRule in
                let trigger = ContentBlockerRuleTrigger(
                    unlessDomain: wildcardDomains
                )
                let action = ContentBlockerRuleAction(
                    type: cssRule.type == .blocking ? "css-display-none" : "ignore-previous-rules",
                    selector: selector
                )

                return ContentBlockerRule(trigger: trigger, action: action)
            }
        }
        .flatMap { $0 }
        // For now, we have to stick only to rules which would cause
        // the selector to not display. ignore-previous-rules
        // isn't supported with a selector AFAICT
        .filter { $0.action.type == "css-display-none" }

        return rules
    }
}
