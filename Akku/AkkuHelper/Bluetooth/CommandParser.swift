//
//  CommandParser.swift
//  Akku
//
//  Created by Jari on 31/10/2018.
//  Copyright © 2018 JARI.IO. All rights reserved.
//

import Foundation

class CommandParser {
    
    // MARK: -
    // MARK: Vendor specific command types
    
    static let appleVscCommandType = "IPHONEACCEV";
    static let xeventVscCommandType = "XEVENT"
    
    // MARK: -
    // MARK: AT Command parser
    
    static func parseCommand (_ payload: String) -> BatteryInfo? {
        if payload.count < 4 {
            return nil
        }
        let endOfAT = payload.index(payload.startIndex, offsetBy: 3)
        let start = payload[..<endOfAT]
        if start != "AT+" {
            return nil
        }
        
        if let registerIndex = payload[endOfAT...].index(of: "=") {
            let type = String(payload[endOfAT..<registerIndex])
            let valueStart = payload.index(registerIndex, offsetBy: 1)
            let value = payload[valueStart...]
            
            let args = value.split(separator: ",").map({ String($0) })
            return self.processCommand(type: type, args: args)
        }
        
        return nil
    }
    
    static fileprivate func processCommand (type: String, args: [String]) -> BatteryInfo? {
        debugPrint(type, args)
        
        switch (type) {
        case CommandParser.appleVscCommandType:
            return getBatteryFromAppleVsc(args)
        default:
            return nil
        }
    }
    
    // MARK: -
    // MARK: Vendor specific comnmand processors
    
    static fileprivate func getBatteryFromAppleVsc (_ args: [String]) -> BatteryInfo? {
        let intArgs = args.map({ $0.trimmingCharacters(in: [" ", "\r", "\n"]) }).compactMap { Int($0) }
        if intArgs.count == 0 {
            NSLog("getBatteryFromAppleVsc WARN: received a apple vsc without a length indicator")
            return nil
        }
        
        let length = intArgs[0]
        
        if length == 0 {
            NSLog("getBatteryFromAppleVsc WARN: received a apple vsc with 0 keyvals")
            return nil
        }
        
        if intArgs.count - 1 < length * 2 {
            NSLog("getBatteryFromAppleVsc WARN: received a apple vsc that contains a invalid length")
        }
        
        var battInfo = BatteryInfo(percentage: nil, docked: nil)
        var index = 1
        
        repeat {
            let key = intArgs[index]
            let val = intArgs[index + 1]
            
            switch key {
            case 1: // Battery level
                let percentage = (val + 1) * 10
                
                if percentage > 100 || percentage < 0 {
                    NSLog("getBatteryFromAppleVsc WARN: illegal battery value! (\(percentage)%)")
                    break
                }
                
                battInfo.percentage = percentage
                
                break
            case 2: // Dock state
                battInfo.docked = val == 1
            default:
                break
            }
            
            index += 2
        } while index / 2 < length
        
        
        
        
        return battInfo
    }
    
    static func getBatteryFromXEventVsc () {
        // TODO
    }
}
