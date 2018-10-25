//
//  HelperAuthorization.swift
//  SwiftPrivilegedHelper
//
//  Created by Erik Berglund on 2018-10-01.
//  Copyright © 2018 Erik Berglund. All rights reserved.
//

import Foundation

enum HelperAuthorizationError: Error {
    case message(String)
}

class HelperAuthorization {

    // MARK: -
    // MARK: Variables

    // FIXME: Add all functions that require authentication here.

    static let authorizationRights = [
        HelperAuthorizationRight(command: #selector(HelperProtocol.runCommandLs(withPath:authData:completion:)),
                                 description: "SwiftPrivilegedHelper wants to run the command /bin/ls",
                                 ruleCustom: [kAuthorizationRightKeyClass: "user", kAuthorizationRightKeyGroup: "admin", kAuthorizationRightKeyVersion: 1])
    ]

    // MARK: -
    // MARK: AuthorizationRights

    static func authorizationRight(forCommand command: Selector) -> HelperAuthorizationRight? {
        return self.authorizationRights.first { $0.command == command }
    }

    static func authorizationRightsUpdateDatabase() throws {
        guard let authRef = try self.emptyAuthorizationRef() else {
            throw HelperAuthorizationError.message("Failed to get empty authorization ref")
        }

        for authorizationRight in self.authorizationRights {

            var osStatus = errAuthorizationSuccess
            var currentRule: CFDictionary?

            osStatus = AuthorizationRightGet(authorizationRight.name, &currentRule)
            if osStatus == errAuthorizationDenied || self.authorizationRuleUpdateRequired(currentRule, authorizationRight: authorizationRight) {
                osStatus = AuthorizationRightSet(authRef,
                                                 authorizationRight.name,
                                                 authorizationRight.rule(),
                                                 authorizationRight.description as CFString,
                                                 nil,
                                                 nil)
            }

            guard osStatus == errAuthorizationSuccess else {
                NSLog("AuthorizationRightSet or Get failed with error: \(String(describing: SecCopyErrorMessageString(osStatus, nil)))")
                continue
            }
        }
    }

    static func authorizationRuleUpdateRequired(_ currentRuleCFDict: CFDictionary?, authorizationRight: HelperAuthorizationRight) -> Bool {
        guard let currentRuleDict = currentRuleCFDict as? [String: Any] else {
            return true
        }
        let newRule = authorizationRight.rule()
        if CFGetTypeID(newRule) == CFStringGetTypeID() {
            if
                let currentRule = currentRuleDict[kAuthorizationRightKeyRule] as? [String],
                let newRule = authorizationRight.ruleConstant {
                return currentRule != [newRule]

            }
        } else if CFGetTypeID(newRule) == CFDictionaryGetTypeID() {
            if let currentVersion = currentRuleDict[kAuthorizationRightKeyVersion] as? Int,
                let newVersion = authorizationRight.ruleCustom?[kAuthorizationRightKeyVersion] as? Int {
                return currentVersion != newVersion
            }
        }
        return true
    }

    // MARK: -
    // MARK: Authorization Wrapper

    private static func executeAuthorizationFunction(_ authorizationFunction: () -> (OSStatus) ) throws {
        let osStatus = authorizationFunction()
        guard osStatus == errAuthorizationSuccess else {
            throw HelperAuthorizationError.message(String(describing: SecCopyErrorMessageString(osStatus, nil)))
        }
    }

    // MARK: -
    // MARK: AuthorizationRef

    static func authorizationRef(_ rights: UnsafePointer<AuthorizationRights>?,
                                 _ environment: UnsafePointer<AuthorizationEnvironment>?,
                                 _ flags: AuthorizationFlags) throws -> AuthorizationRef? {
        var authRef: AuthorizationRef?
        try executeAuthorizationFunction { AuthorizationCreate(rights, environment, flags, &authRef) }
        return authRef
    }

    static func authorizationRef(fromExternalForm data: NSData) throws -> AuthorizationRef? {

        // Create an AuthorizationExternalForm from it's data representation
        var authRef: AuthorizationRef?
        let authRefExtForm: UnsafeMutablePointer<AuthorizationExternalForm> = UnsafeMutablePointer.allocate(capacity: kAuthorizationExternalFormLength * MemoryLayout<AuthorizationExternalForm>.size)
        memcpy(authRefExtForm, data.bytes, data.length)

        // Extract the AuthorizationRef from it's external form
        try executeAuthorizationFunction { AuthorizationCreateFromExternalForm(authRefExtForm, &authRef) }
        return authRef
    }


    // MARK: -
    // MARK: Empty Authorization Refs

    static func emptyAuthorizationRef() throws -> AuthorizationRef? {
        var authRef: AuthorizationRef?

        // Create an empty AuthorizationRef
        try executeAuthorizationFunction { AuthorizationCreate(nil, nil, [], &authRef) }
        return authRef
    }

    static func emptyAuthorizationExternalForm() throws -> AuthorizationExternalForm? {

        // Create an empty AuthorizationRef
        guard let authorizationRef = try self.emptyAuthorizationRef() else { return nil }

        // Make an external form of the AuthorizationRef
        var authRefExtForm = AuthorizationExternalForm()
        try executeAuthorizationFunction { AuthorizationMakeExternalForm(authorizationRef, &authRefExtForm) }
        return authRefExtForm
    }

    static func emptyAuthorizationExternalFormData() throws -> NSData? {
        guard var authRefExtForm = try self.emptyAuthorizationExternalForm() else { return nil }

        // Encapsulate the external form AuthorizationRef in an NSData object
        return NSData(bytes: &authRefExtForm, length: kAuthorizationExternalFormLength)
    }

    // MARK: -
    // MARK: Verification

    static func verifyAuthorization(_ authExtData: NSData?, forCommand command: Selector) throws {

        // Verity that the passed authExtData looks reasonable
        guard let authorizationExtData = authExtData, authorizationExtData.length == kAuthorizationExternalFormLength else {
            throw HelperAuthorizationError.message("Invalid Authorization External Form Data")
        }
        
        // Convert the external form to an AuthorizationRef
        guard let authorizationRef = try self.authorizationRef(fromExternalForm: authorizationExtData) else {
            throw HelperAuthorizationError.message("Failed to convert the Authorization External Form to an Authorization Reference")
        }

        // Get the authorization right struct for the passed command
        guard let authorizationRight = self.authorizationRight(forCommand: command) else {
            throw HelperAuthorizationError.message("Failed to get the correct authorization right for command: \(command)")
        }

        // Verity the user has the right to run the passed command
        try self.verifyAuthorization(authorizationRef, forAuthenticationRight: authorizationRight)
    }

    static func verifyAuthorization(_ authRef: AuthorizationRef, forAuthenticationRight authRight: HelperAuthorizationRight) throws {

        // Get the authorization name in the correct format
        guard let authRightName = (authRight.name as NSString).utf8String else {
            throw HelperAuthorizationError.message("Failed to convert authorization name to cString")
        }

        // Create an AuthorizationItem using the authorization right name
        var authItem = AuthorizationItem(name: authRightName, valueLength: 0, value: UnsafeMutableRawPointer(bitPattern: 0), flags: 0)

        // Create the AuthorizationRights for using the AuthorizationItem
        var authRights = AuthorizationRights(count: 1, items: &authItem)

        // Check if the user is authorized for the AuthorizationRights. If not the user might be asked for an admin credential.
        try executeAuthorizationFunction { AuthorizationCopyRights(authRef, &authRights, nil, [.extendRights, .interactionAllowed], nil) }
    }
}
