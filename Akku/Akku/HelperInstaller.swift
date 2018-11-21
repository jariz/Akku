//
//  Helperinstaller.swift
//  Akku
//
//  Created by Jari on 25/10/2018.
//  Copyright © 2018 JARI.IO. All rights reserved.
//

import Foundation
import Cocoa

class HelperInstaller: NSViewController {
    
    // MARK: -
    // MARK: Lifecycle
    
    override func awakeFromNib() {
        let delegate = NSApplication.shared.delegate as! AppDelegate
        
        // TODO: bind disclosure button
        
        self.buttonInstallHelper.bind(.enabled,
                                      to: delegate,
                                      withKeyPath: delegate.helperIsInstalledKeyPath,
                                      options: [.continuouslyUpdatesValue: true,
                                                .valueTransformerName: NSValueTransformerName.negateBooleanTransformerName])
    }
    
    // MARK: -
    // MARK: IBOutlets
    
    @IBOutlet weak var buttonInstallHelper: NSButton!
    @IBOutlet weak var disclosureButton: NSButton!
    @IBOutlet weak var disclosureText: NSTextField!
    
    // MARK: -
    // MARK: IBActions
    
    @IBAction func buttonInstallHelper(_ sender: Any) {
        let delegate = NSApplication.shared.delegate as! AppDelegate
        do {
            if try delegate.helperInstall() {
                OperationQueue.main.addOperation {
                    delegate.setValue(true, forKey: delegate.helperIsInstalledKeyPath)
                }
                delegate.startListeningIfHelperAvailable()
                return
            } else {
                OperationQueue.main.addOperation {
                    delegate.alertWithError("Failed install helper with unknown error.")
                }
            }
        } catch {
            OperationQueue.main.addOperation {
                delegate.alertWithError("Failed to install helper with error: \(error)")
            }
        }
        OperationQueue.main.addOperation {
            delegate.setValue(false, forKey: delegate.helperIsInstalledKeyPath)
        }
    }
    
    @IBAction func buttonDisclosure (_ sender: Any) {
        disclosureText.alphaValue = disclosureButton.state == .on ? 0 : 1
        
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.25
            disclosureText.animator().alphaValue = disclosureButton.state == .on ? 1 : 0
        }
        
//        var size = self.size
//        size.height += 40
//        self.view.setBoundsSize(size)
    }
    
}
