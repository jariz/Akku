//
//  EventPacket.swift
//  AkkuLowLevel
//
//  Created by Jari on 15/10/2018.
//  Copyright © 2018 JARI.IO. All rights reserved.
//

import Foundation
import IOBluetooth

typealias RawBTAddress = (UInt8, UInt8, UInt8, UInt8, UInt8, UInt8)

class EventPacket {
    
    // MARK: -
    // MARK: Public static constants
    
    static let connectionRequestLength = 12
    
    // MARK: -
    // MARK: Public constants
    
    let eventCode: UInt8;
    let parameterLength: UInt8;
    
    // MARK: -
    // MARK: Connection request specific fields
    var status: UInt8?;
    var connectionHandle: UInt16?;
    var addr: RawBTAddress?;
    var linkType: UInt8?;
    var encryptionMode: UInt8?;
    
    // MARK: -
    // MARK: Initializers
    
    init (pointer: UnsafeMutableBufferPointer<UInt8>) {
        let data = Data(buffer: pointer)
        
        self.eventCode = data[0...0].withUnsafeBytes { $0.pointee }
        self.parameterLength = data[1...1].withUnsafeBytes { $0.pointee }
        
        if self.eventCode == kBluetoothHCIEventConnectionComplete {
            if data.count < EventPacket.connectionRequestLength {
                NSLog("EventPacket WARN: received a kBluetoothHCIEventConnectionComplete but the packet length was too short, ignoring...")
                return
            }
            
            let status: UInt8 = data[2...2].withUnsafeBytes { $0.pointee }
            let connectionHandle: UInt16 = data[3...4].withUnsafeBytes { $0.pointee }
            
            // the address is reversed for whatever reason...
            var addrData = data[5...10]
            addrData.reverse()
            
            let addr: RawBTAddress = addrData.withUnsafeBytes { $0.pointee }
            let linkType: UInt8 = data[11...11].withUnsafeBytes { $0.pointee }
            let encryptionMode: UInt8 = data[12...12].withUnsafeBytes { $0.pointee }
            
            self.status = status
            self.connectionHandle = connectionHandle
            self.addr = addr
            self.linkType = linkType
            self.encryptionMode = encryptionMode
        }
    }
}
