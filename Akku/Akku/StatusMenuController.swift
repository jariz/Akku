//
//  StatusMenuController.swift
//  Akku
//
//  Created by Jari on 25/10/2018.
//  Copyright © 2018 JARI.IO. All rights reserved.
//

import Foundation
import Cocoa
import IOBluetooth
import IOBluetoothUI

class StatusMenuController: NSObject {
    
    // MARK: Private vars
    
    private var popover: NSPopover?;
    private var menu: NSMenu?;
    private var batteryInfo: [String: BatteryInfo] = [:]
    
    // MARK: Private constants
    
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    
    // MARK: -
    // MARK: Lifecycle
    
    func initStatusItem () {
        // we don't initialize the statusitem on init
        // because we want to defer that until AppDelegate is done checking the helper status
        
        guard let button = statusItem.button else {
            return
        }
        button.image = #imageLiteral(resourceName: "akku_noconnect")
        button.target = self
        
        if let popover = self.popover, popover.isShown {
            self.closePopover(nil)
        }
        
        let delegate = NSApplication.shared.delegate as! AppDelegate
        OperationQueue.main.addOperation {
            if delegate.helperIsInstalled {
                self.initMenu()
            } else {
                button.action = #selector(StatusMenuController.togglePopover(_:))
                self.initPopover()
                self.showPopover()
            }
        }
    }
    
    // MARK: -
    // MARK: Menu control functions
    
    func initMenu () {
        menu = NSMenu(title: "Akku status")
        statusItem.menu = menu!;
        
        buildMenu()
        
        IOBluetoothDevice.register(forConnectNotifications: self, selector: #selector(buildMenu))
    }
    
    fileprivate func getAddressString(for address: BluetoothDeviceAddress) -> String? {
        var address = address
        guard let addressString = IOBluetoothNSStringFromDeviceAddress(&address) else {
            return nil
        }
        return addressString
    }
    
    fileprivate func getBatteryInfo(for addressString: String) -> BatteryInfo {
        return self.batteryInfo[addressString] ?? BatteryInfo()
    }

    func reportDockChange(address: BluetoothDeviceAddress, docked: Bool) {
        guard let addressString = self.getAddressString(for: address) else {
            return
        }
        
        var batteryInfo = self.getBatteryInfo(for: addressString)
        batteryInfo.docked = docked
        self.batteryInfo[addressString] = batteryInfo
        buildMenu()
    }
    
    func reportBatteryChange(address: BluetoothDeviceAddress, percentage: Int) {
        guard let addressString = self.getAddressString(for: address) else {
            return
        }
        
        self.shouldShowNotification(addressString, percentage)
        
        var batteryInfo = self.getBatteryInfo(for: addressString)
        batteryInfo.percentage = percentage
        self.batteryInfo[addressString] = batteryInfo
        buildMenu()
    }
    
    func shouldShowNotification (_ addressString: String, _ percentage: Int) {
        let warnAt = UserDefaults.standard.string(forKey: "warnAt") ?? "20%"
        let devices = IOBluetoothDevice.pairedDevices() as! [IOBluetoothDevice]
        
        guard warnAt == "\(String(percentage))%",
            let device = devices.first(where: { device in device.addressString == addressString }) else {
            return
        }
        
        let noti = NSUserNotification()
        noti.hasActionButton = false
        noti.title = "Headset will run out of battery soon."
        noti.informativeText = "\(device.name!) only has \(String(percentage))% battery left."
        NSUserNotificationCenter.default.deliver(noti)
    }
    
    @objc func warnSettingChange (sender: NSMenuItem) {
        UserDefaults.standard.set(sender.title, forKey: "warnAt")
        
        buildMenu()
    }
    
    @objc func buildMenu () {
        guard let menu = self.menu else {
            return
        }
        
        menu.removeAllItems()
        
        let devices = (IOBluetoothDevice.pairedDevices() as! [IOBluetoothDevice])
            .filter { $0.isConnected() && $0.isHandsFreeDevice }
        
        guard devices.count != 0 else {
            menu.addItem(withTitle: "No connected handsfree devices.", action: nil, keyEquivalent: "")
            statusItem.button!.image = NSImage(named: NSImage.Name("akku_noconnect"))
            buildSettings()
            return
        }
        
        guard let button = statusItem.button else {
            return
        }
        
        for device in devices {
            menu.addItem(withTitle: device.name, action: nil, keyEquivalent: "")
            let batteryMenuItem = NSMenuItem()
            
            if let batteryInfo = self.batteryInfo[device.addressString] {
                let controller = BatteryMenuItemController(nibName: NSNib.Name("BatteryMenuItem"), bundle: nil)
                
                if let percentage = batteryInfo.percentage {
                    controller.setProgress(value: Double(percentage))
                    button.image = NSImage(named: NSImage.Name("akku_" + String(percentage)))
                    
                    if percentage <= 20 {
                        if #available(OSX 10.14, *) {
                            button.contentTintColor = .systemRed
                        } else {
                            button.image = button.image?.tinting(with: .systemRed)
                        }
                    } else if #available(OSX 10.14, *) {
                        button.contentTintColor = nil
                    }
                }
                
                if let docked = batteryInfo.docked {
                    controller.setDocked(docked: docked)
                }
                
                batteryMenuItem.view = controller.view
                
            } else {
                batteryMenuItem.title = "No reported battery state yet, try reconnecting."
                statusItem.button!.image = NSImage(named: NSImage.Name("akku_noconnect"))
            }
            
            menu.addItem(batteryMenuItem)

            device.register(forDisconnectNotification: self, selector: #selector(onDeviceDisconnect(sender:device:)))
        }
        
        buildSettings()
    }
    
    @objc
    func onDeviceDisconnect (sender: AnyObject, device: IOBluetoothDevice) {
        self.batteryInfo.removeValue(forKey: device.addressString)
        self.buildMenu()
    }
    
    func buildSettings () {
        guard let menu = self.menu else { return }
        
        menu.addItem(NSMenuItem.separator())
        
        let warnAtItem = NSMenuItem(title: "Show notification at...", action: nil, keyEquivalent: "")
        let submenu = NSMenu(title: "Show notification at")
        func addWarnAtItem(value: String) {
            let warnAt = UserDefaults.standard.string(forKey: "warnAt") ?? "20%"
            let item = NSMenuItem(title: value, action: #selector(warnSettingChange(sender:)), keyEquivalent: "")
            item.target = self
            item.state = warnAt == value ? .on : .off
            submenu.addItem(item)
        }
        
        for i in 0...4 {
            addWarnAtItem(value: String(describing: i * 10) + "%")
        }
        
        addWarnAtItem(value: "Never")
        
        warnAtItem.submenu = submenu
        menu.addItem(warnAtItem)
    }
    
    // MARK: -
    // MARK: Popover control functions
    
    func initPopover () {
        popover = NSPopover()
        popover!.contentViewController = HelperInstaller(nibName: NSNib.Name("HelperInstaller"), bundle: nil)
    }
    
    func showPopover () {
        guard let button = statusItem.button,
        let popover = self.popover else {
            return
        }
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: NSRectEdge.minY)
    }
    
    func closePopover(_ sender: Any?) {
        popover!.performClose(sender)
    }
    
    @objc func togglePopover(_ sender: Any) {
        guard let popover = self.popover else { return }
        
        if popover.isShown {
            closePopover(sender)
        } else {
            showPopover()
        }
    }

}
