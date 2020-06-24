//
//  ContentBlockerRule.swift
//  Shut Up Core
//
//  Created by Ricky Romero on 6/23/20.
//  Copyright © 2020 Ricky Romero. All rights reserved.
//

struct ContentBlockerRule: Encodable {
    let trigger: ContentBlockerRuleTrigger
    let action: ContentBlockerRuleAction
}

struct ContentBlockerRuleTrigger: Encodable {
    let urlFilter = ".*"
    let unlessDomain: [String]
}

struct ContentBlockerRuleAction: Encodable {
    let type: String
    let selector: String
}

struct KebabKey: CodingKey {
    var stringValue: String
    var intValue: Int?

    init?(stringValue key: String) {
        var kebabString = ""
        for (index, letter) in key.enumerated() {
            if index > 0 && letter.isUppercase {
                kebabString.append("-")
            }
            kebabString.append(letter)
        }
        self.stringValue = kebabString.lowercased()
    }

    init?(intValue: Int) {
        self.stringValue = "\(intValue)"
        self.intValue = intValue
    }
}
