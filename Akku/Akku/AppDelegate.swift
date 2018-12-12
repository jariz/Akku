//
//  AppDelegate.swift
//  SwiftPrivilegedHelperApplication / Akku
//
//  Created by Erik Berglund on 2018-10-01.
//  Copyright © 2018 Erik Berglund. All rights reserved.
//  Copyright © 2018 Jari Zwarts. All rights reserved.
//

import Cocoa
import ServiceManagement
import IOBluetooth
import Sentry
import SwiftyBeaver
import Sparkle
let log = SwiftyBeaver.self

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate, AppProtocol {
    
    // MARK: -
    // MARK: Variables
    private var currentHelperConnection: NSXPCConnection?
    private var timeoutCheck: Timer?

    @objc dynamic var helperIsInstalled = false
    let helperIsInstalledKeyPath: String
    
    // MARK: -
    // MARK: IBOutlets
    
    @IBOutlet weak var statusMenuController: StatusMenuController?

    // MARK: -
    // MARK: NSApplicationDelegate Methods

    override init() {
        self.helperIsInstalledKeyPath = NSStringFromSelector(#selector(getter: self.helperIsInstalled))
        super.init()
    }

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // fire up logging
        let file = FileDestination()
        let console = ConsoleDestination()
        let url = try? FileManager.default.url(for: .libraryDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        file.logFileURL = url?.appendingPathComponent("Logs/Akku.log")
        console.format = "$DHH:mm:ss$d $C$L - $M"
        file.format = "$Ddd-MM-yyyy HH:mm:ss$d $L $F:$l - $M"
        log.addDestination(file)
        log.addDestination(console)
        
        // fire up sentry
        do {
            Client.shared = try Client(dsn: "https://7c90f578bae24cafb69e519f4a692036@sentry.io/1338198")
            try Client.shared?.startCrashHandler()
        } catch let error {
            log.error(error)
        }
        
        // Check if the current embedded helper tool is installed on the machine.
        
        self.helperStatus { installed in
            if installed {
                self.startListeningIfHelperAvailable()
            }
            
            OperationQueue.main.addOperation {
                self.setValue(installed, forKey: self.helperIsInstalledKeyPath)
                
                guard let statusMenuController = self.statusMenuController else {
                    return
                }

                statusMenuController.initStatusItem()
            }
        }
        
        // TODO: this is kinda hacky??
        // but... invoking a non existing helper does not seem to cause any errors for whatever reason.
        self.timeoutCheck = Timer(timeInterval: 2.5, target: self, selector: #selector(timerHit), userInfo: nil, repeats: false)
        
        RunLoop.current.add(self.timeoutCheck!, forMode: .common)
    }
    
    // MARK: -
    // MARK: Timer callbacks
    
    @objc
    func timerHit () {
        if !self.helperIsInstalled {
            guard let statusMenuController = self.statusMenuController else {
                return
            }
            
            statusMenuController.initStatusItem()
        }
    }

    // MARK: -
    // MARK: Error handling
    
    func alertWithError(_ error: String) {
        // FIXME: improve all this a bit UI-wise...
        // Currently there's a lot of stuff that can go wrong. But it all leads back to this single function.
        // Retry buttons, and perhaps something a bit more subtle than a modal...
        
        log.error(error)
        OperationQueue.main.addOperation {
            let alert = NSAlert()
            alert.informativeText = error
            alert.runModal()
        }
    }

    // MARK: -
    // MARK: AppProtocol Methods
    
    func reportDockChange(address: BluetoothDeviceAddress, docked: Bool) {
        log.debug(address, "docked", String(docked))
        OperationQueue.main.addOperation {
            self.statusMenuController?.reportDockChange(address: address, docked: docked)
        }
    }
    
    func reportBatteryChange(address: BluetoothDeviceAddress, percentage: Int) {
        log.debug(address, "battery", String(percentage))
        OperationQueue.main.addOperation {
            self.statusMenuController?.reportBatteryChange(address: address, percentage: percentage)
        }
    }
    
    // MARK: -
    // MARK: Helper commands
    
    func startListeningIfHelperAvailable () {
        if let helper = self.helper(nil) {
            helper.startListening(completion: { error in
                if error != nil {
                    self.alertWithError(error!.localizedDescription)
                }
            })
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
            log.error("Helper connection was closed with error: \(error)")
            if let onCompletion = completion { onCompletion(false) }
        }) as? HelperProtocol else { return nil }
        return helper
    }

    func helperStatus(completion: @escaping (_ installed: Bool) -> Void) {

        // Compare the CFBundleShortVersionString from the Info.plist in the helper inside our application bundle with the one on disk.

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

