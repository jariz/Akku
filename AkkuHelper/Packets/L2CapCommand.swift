//
//  L2CapCommand.swift
//  Akku
//
//  Created by Jari on 31/10/2018.
//  Copyright © 2018 JARI.IO. All rights reserved.
//

import Foundation
import IOBluetooth

class L2CapCommand {
    
    // MARK: -
    // MARK: Public static constants
    
    static let baseLength = 4
    static let connectionRequestLength = 6
    static let connectionResponseLength = 4
    
    // MARK: -
    // MARK: Private constants
    
    private let parent: L2CapPacket
    
    // MARK: -
    // MARK: Public constants
    
    let commandCode: UInt8;
    let commandID: UInt8;
    let commandLength: UInt16;
    
    var sourceCID: UInt16?;
    
    // MARK: Connection request command specific fields
    
    var psm: UInt16?;
    
    // MARK: Connection response command specific fields
    
    var destinationCID: UInt16?;
    var result: UInt16?;
    
    // MARK: -
    // MARK: Initializers
    
    init? (pointer: UnsafeMutableBufferPointer<UInt8>, parent: L2CapPacket) {
        self.parent = parent
        
        let data = Data(buffer: pointer)
        
        if (data.count < L2CapCommand.baseLength) {
            return nil
        }
        
        self.commandCode = data[0...0].withUnsafeBytes { $0.pointee }
        self.commandID = data[1...1].withUnsafeBytes { $0.pointee }
        self.commandLength = data[2...3].withUnsafeBytes { $0.pointee }
        
        if self.commandCode == UInt8(kBluetoothL2CAPCommandCodeConnectionRequest.rawValue) {
            if (data.count < L2CapCommand.baseLength + L2CapCommand.connectionRequestLength) {
                return nil;
            }
            
            let psm: UInt16 = data[4...5].withUnsafeBytes { $0.pointee }
            let sourceCID: UInt16 = data[6...7].withUnsafeBytes { $0.pointee }
            self.psm = psm
            self.sourceCID = sourceCID
        }
        
        if (self.commandCode == UInt8(kBluetoothL2CAPCommandCodeConnectionResponse.rawValue)) {
            if (data.count < L2CapCommand.baseLength + L2CapCommand.connectionResponseLength) {
                return nil;
            }
            
            let destinationCID: UInt16 = data[4...5].withUnsafeBytes { $0.pointee }
            let sourceCID: UInt16 = data[6...7].withUnsafeBytes { $0.pointee }
            let result: UInt16 = data[8...9].withUnsafeBytes { $0.pointee }
            
            self.destinationCID = destinationCID
            self.sourceCID = sourceCID
            self.result = result
        }
    }
}
