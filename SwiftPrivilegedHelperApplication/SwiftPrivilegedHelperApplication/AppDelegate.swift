//
//  AppDelegate.swift
//  SwiftPrivilegedHelperApplication
//
//  Created by Erik Berglund on 2018-10-01.
//  Copyright © 2018 Erik Berglund. All rights reserved.
//

import Cocoa
import ServiceManagement

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate, AppProtocol {

    // MARK: -
    // MARK: IBOutlets

    @IBOutlet weak var window: NSWindow!

    @IBOutlet weak var buttonInstallHelper: NSButton!
    @IBOutlet weak var buttonDestroyCachedAuthorization: NSButton!
    @IBOutlet weak var buttonRunCommand: NSButton!

    @IBOutlet weak var textFieldHelperInstalled: NSTextField!
    @IBOutlet weak var textFieldAuthorizationCached: NSTextField!
    @IBOutlet weak var textFieldInput: NSTextField!

    @IBOutlet var textViewOutput: NSTextView!

    @IBOutlet weak var checkboxRequireAuthentication: NSButton!
    @IBOutlet weak var checkboxCacheAuthentication: NSButton!

    // MARK: -
    // MARK: Variables

    private var currentHelperConnection: NSXPCConnection?

    @objc dynamic private var currentHelperAuthData: NSData?
    private let currentHelperAuthDataKeyPath: String

    @objc dynamic private var helperIsInstalled = false
    private let helperIsInstalledKeyPath: String

    // MARK: -
    // MARK: Computed Variables

    var inputPath: String? {
        if self.textFieldInput.stringValue.isEmpty {
            self.textViewOutput.appendText("You need to enter a path to a directory!")
            return nil
        }

        let inputURL = URL(fileURLWithPath: self.textFieldInput.stringValue)
        do {
            guard try inputURL.checkResourceIsReachable() else { return nil }
        } catch {
            self.textViewOutput.appendText("\(self.textFieldInput.stringValue) is not a valid path!")
            return nil
        }
        return inputURL.path
    }

    // MARK: -
    // MARK: NSApplicationDelegate Methods

    override init() {
        self.currentHelperAuthDataKeyPath = NSStringFromSelector(#selector(getter: self.currentHelperAuthData))
        self.helperIsInstalledKeyPath = NSStringFromSelector(#selector(getter: self.helperIsInstalled))
        super.init()
    }

    override func awakeFromNib() {
        self.configureBindings()
    }

    func applicationDidFinishLaunching(_ aNotification: Notification) {

        // Update the current authorization database right
        // This will prmpt the user for authentication if something needs updating.

        do {
            try HelperAuthorization.authorizationRightsUpdateDatabase()
        } catch {
            self.textViewOutput.appendText("Failed to update the authorization database rights with error: \(error)")
        }

        // Check if the current embedded helper tool is installed on the machine.

        self.helperStatus { installed in
            OperationQueue.main.addOperation {
                self.textFieldHelperInstalled.stringValue = (installed) ? "Yes" : "No"
                self.setValue(installed, forKey: self.helperIsInstalledKeyPath)
            }
        }
    }

    // MARK: -
    // MARK: Initialization

    func configureBindings() {

        // Button: Install Helper
        self.buttonInstallHelper.bind(.enabled,
                                      to: self,
                                      withKeyPath: self.helperIsInstalledKeyPath,
                                      options: [.continuouslyUpdatesValue: true,
                                                .valueTransformerName: NSValueTransformerName.negateBooleanTransformerName])

        // Button: Run Command
        self.buttonRunCommand.bind(.enabled,
                                   to: self,
                                   withKeyPath: self.helperIsInstalledKeyPath,
                                   options: [.continuouslyUpdatesValue: true])

    }

    // MARK: -
    // MARK: IBActions

    @IBAction func buttonInstallHelper(_ sender: Any) {
        do {
            if try self.helperInstall() {
                OperationQueue.main.addOperation {
                    self.textViewOutput.appendText("Helper installed successfully.")
                    self.textFieldHelperInstalled.stringValue = "Yes"
                    self.setValue(true, forKey: self.helperIsInstalledKeyPath)
                }
                return
            } else {
                OperationQueue.main.addOperation {
                    self.textFieldHelperInstalled.stringValue = "No"
                    self.textViewOutput.appendText("Failed install helper with unknown error.")
                }
            }
        } catch {
            OperationQueue.main.addOperation {
                self.textViewOutput.appendText("Failed to install helper with error: \(error)")
            }
        }
        OperationQueue.main.addOperation {
            self.textFieldHelperInstalled.stringValue = "No"
            self.setValue(false, forKey: self.helperIsInstalledKeyPath)
        }
    }

    @IBAction func buttonDestroyCachedAuthorization(_ sender: Any) {
        self.currentHelperAuthData = nil
        self.textFieldAuthorizationCached.stringValue = "No"
        self.buttonDestroyCachedAuthorization.isEnabled = false
    }

    @IBAction func buttonRunCommand(_ sender: Any) {
        guard
            let inputPath = self.inputPath,
            let helper = self.helper(nil) else { return }

        if self.checkboxRequireAuthentication.state == .on {
            do {
                guard let authData = try self.currentHelperAuthData ?? HelperAuthorization.emptyAuthorizationExternalFormData() else {
                    self.textViewOutput.appendText("Failed to get the empty authorization external form")
                    return
                }

                helper.runCommandLs(withPath: inputPath, authData: authData) { (exitCode) in
                    OperationQueue.main.addOperation {

                        // Verify that authentication was successful

                        guard exitCode != kAuthorizationFailedExitCode else {
                            self.textViewOutput.appendText("Authentication Failed")
                            return
                        }

                        self.textViewOutput.appendText("Command exit code: \(exitCode)")
                        if self.checkboxCacheAuthentication.state == .on, self.currentHelperAuthData == nil {
                            self.currentHelperAuthData = authData
                            self.textFieldAuthorizationCached.stringValue = "Yes"
                            self.buttonDestroyCachedAuthorization.isEnabled = true
                        }

                    }
                }
            } catch {
                self.textViewOutput.appendText("Command failed with error: \(error)")
            }
        } else {
            helper.runCommandLs(withPath: inputPath) { (exitCode) in
                self.textViewOutput.appendText("Command exit code: \(exitCode)")
            }
        }
    }

    // MARK: -
    // MARK: AppProtocol Methods

    func log(stdOut: String) {
        guard !stdOut.isEmpty else { return }
        OperationQueue.main.addOperation {
            self.textViewOutput.appendText(stdOut)
        }
    }

    func log(stdErr: String) {
        guard !stdErr.isEmpty else { return }
        OperationQueue.main.addOperation {
            self.textViewOutput.appendText(stdErr)
        }
    }

    // MARK: -
    // MARK: Helper Connection Methods

    func helperConnection() -> NSXPCConnection? {
        guard self.currentHelperConnection == nil else {
            return self.currentHelperConnection
        }

        let connection = NSXPCConnection(machServiceName: HelperConstants.machServiceName, options: .privileged)
        connection.exportedInterface = NSXPCInterface(with: AppProtocol.self)
        connection.exportedObject = self
        connection.remoteObjectInterface = NSXPCInterface(with: HelperProtocol.self)
        connection.invalidationHandler = {
            self.currentHelperConnection?.invalidationHandler = nil
            OperationQueue.main.addOperation {
                self.currentHelperConnection = nil
            }
        }

        self.currentHelperConnection = connection
        self.currentHelperConnection?.resume()

        return self.currentHelperConnection
    }

    func helper(_ completion: ((Bool) -> Void)?) -> HelperProtocol? {

        // Get the current helper connection and return the remote object (Helper.swift) as a proxy object to call functions on.

        guard let helper = self.helperConnection()?.remoteObjectProxyWithErrorHandler({ error in
            self.textViewOutput.appendText("Helper connection was closed with error: \(error)")
            if let onCompletion = completion { onCompletion(false) }
        }) as? HelperProtocol else { return nil }
        return helper
    }

    func helperStatus(completion: @escaping (_ installed: Bool) -> Void) {

        // Comppare the CFBundleShortVersionString from the Info.plisin the helper inside our application bundle with the one on disk.

        let helperURL = Bundle.main.bundleURL.appendingPathComponent("Contents/Library/LaunchServices/" + HelperConstants.machServiceName)
        guard
            let helperBundleInfo = CFBundleCopyInfoDictionaryForURL(helperURL as CFURL) as? [String: Any],
            let helperVersion = helperBundleInfo["CFBundleShortVersionString"] as? String,
            let helper = self.helper(completion) else {
                completion(false)
                return
        }

        helper.getVersion { installedHelperVersion in
            completion(installedHelperVersion == helperVersion)
        }
    }

    func helperInstall() throws -> Bool {

        // Install and activate the helper inside our application bundle to disk.

        var cfError: Unmanaged<CFError>?
        var authItem = AuthorizationItem(name: kSMRightBlessPrivilegedHelper, valueLength: 0, value:UnsafeMutableRawPointer(bitPattern: 0), flags: 0)
        var authRights = AuthorizationRights(count: 1, items: &authItem)

        guard
            let authRef = try HelperAuthorization.authorizationRef(&authRights, nil, [.interactionAllowed, .extendRights, .preAuthorize]),
            SMJobBless(kSMDomainSystemLaunchd, HelperConstants.machServiceName as CFString, authRef, &cfError) else {
                if let error = cfError?.takeRetainedValue() { throw error }
                return false
        }

        self.currentHelperConnection?.invalidate()
        self.currentHelperConnection = nil

        return true
    }
}

