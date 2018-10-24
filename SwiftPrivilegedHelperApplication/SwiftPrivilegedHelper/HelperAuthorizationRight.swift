//
//  HelperAuthorizationRight.swift
//  SwiftPrivilegedHelper
//
//  Created by Erik Berglund on 2018-10-01.
//  Copyright © 2018 Erik Berglund. All rights reserved.
//

import Foundation

struct HelperAuthorizationRight {

    let command: Selector
    let name: String
    let description: String
    let ruleCustom: [String: Any]?
    let ruleConstant: String?

    init(command: Selector, name: String? = nil, description: String, ruleCustom: [String: Any]? = nil, ruleConstant: String? = nil) {
        self.command = command
        self.name = name ?? HelperConstants.machServiceName + "." + command.description
        self.description = description
        self.ruleCustom = ruleCustom
        self.ruleConstant = ruleConstant
    }

    func rule() -> CFTypeRef {
        let rule: CFTypeRef
        if let ruleCustom = self.ruleCustom as CFDictionary? {
            rule = ruleCustom
        } else if let ruleConstant = self.ruleConstant as CFString? {
            rule = ruleConstant
        } else {
            rule = kAuthorizationRuleAuthenticateAsAdmin as CFString
        }

        return rule
    }
}

