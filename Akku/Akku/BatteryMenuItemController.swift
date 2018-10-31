//
//  BatteryMenuItemController.swift
//  Akku
//
//  Created by Jari on 31/10/2018.
//  Copyright © 2018 JARI.IO. All rights reserved.
//

import Foundation
import Cocoa

class BatteryMenuItemController: NSViewController {
    
    @IBOutlet weak var progress: NSProgressIndicator!
    @IBOutlet weak var label: NSTextField!
    
    var value: Double?
    var docked: Bool?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.autoresizingMask = .width
        
        setValue()
    }
    
    func setProgress (value: Double) {
        self.value = value
        setValue()
    }
    
    func setDocked (docked: Bool) {
        self.docked = docked
        setValue()
    }
    
    func setValue() {
        if let progress = self.progress, let value = self.value {
            progress.doubleValue = value
            progress.isIndeterminate = self.docked == true
            label.stringValue = String(Int(value)) + "%"
        }
    }
    
    override var representedObject: Any? {
        didSet {
            // Update the view, if already loaded.
        }
    }
}

