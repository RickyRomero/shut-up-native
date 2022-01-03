//
//  ContentBlockerRule.swift
//  Shut Up Core
//
//  Created by Ricky Romero on 6/23/20.
//  See LICENSE.md for license information.
//

struct ContentBlockerRule: Encodable {
    let trigger: ContentBlockerRuleTrigger
    let action: ContentBlockerRuleAction
}

struct ContentBlockerRuleTrigger: Encodable {
    let urlFilter = ".*"
    let unlessDomain: [String]

    enum QualifiedCodingKeys: String, CodingKey {
        case urlFilter, unlessDomain
    }

    enum UnqualifiedCodingKeys: String, CodingKey {
        case urlFilter
    }

    func encode(to encoder: Encoder) throws {
        if unlessDomain.count > 0 {
            var container = encoder.container(keyedBy: QualifiedCodingKeys.self)
            try container.encode(urlFilter, forKey: .urlFilter)
            try container.encode(unlessDomain, forKey: .unlessDomain)
        } else {
            var container = encoder.container(keyedBy: UnqualifiedCodingKeys.self)
            try container.encode(urlFilter, forKey: .urlFilter)
        }
    }
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
