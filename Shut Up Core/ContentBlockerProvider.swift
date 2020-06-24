//
//  ContentBlockerProvider.swift
//  Shut Up Core
//
//  Created by Ricky Romero on 6/23/20.
//  Copyright © 2020 Ricky Romero. All rights reserved.
//

import Foundation

final class ContentBlockerProvider {
    func coalesce() -> [ContentBlockerRule] {
        let selectors = ["img"]
//        let selectors = Stylesheet.main.selectors
        Whitelist.main.load(force: true)
        let whitelist = Whitelist.main.entries

        let rules = selectors.map { selector -> ContentBlockerRule in
            let trigger = ContentBlockerRuleTrigger(
                unlessDomain: whitelist.map { "*\($0)" }
            )
            let action = ContentBlockerRuleAction(
                type: "css-display-none",
                selector: selector
            )

            return ContentBlockerRule(trigger: trigger, action: action)
        }

        return rules
    }
}
