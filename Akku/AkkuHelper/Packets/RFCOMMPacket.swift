//
//  RFCOMMPacket.swift
//  AkkuLowLevel
//
//  Created by Jari on 22/10/2018.
//  Copyright © 2018 JARI.IO. All rights reserved.
//

import Foundation

class RFCOMMPacket {
    
    // MARK: -
    // MARK: Private constants
    
    private let parent: L2CapPacket
    
    // MARK: -
    // MARK: Public constants
    
    let address: UInt8
    let control: UInt8;
    var payloadLength: UInt8;
    var payload: String?;
    
    // MARK: -
    // MARK: Initializers
    
    init(pointer: UnsafeMutableBufferPointer<UInt8>, parent: L2CapPacket) {
        let data = Data(buffer: pointer)
        
        self.parent = parent
        
        self.address = data[0...0].withUnsafeBytes { $0.pointee }
        self.control = data[1...1].withUnsafeBytes { $0.pointee }
        var payloadLength: UInt8 = data[2...2].withUnsafeBytes({ $0.pointee })
        
        // https://github.com/wireshark/wireshark/blob/3a514caaf1e3b36eb284c3a566d489aba6df5392/epan/dissectors/packet-btrfcomm.c#L511
        payloadLength >>= 1
        
        self.payloadLength = payloadLength
        
        if payloadLength > 0 {
            if payloadLength > data.count - 2 {
                NSLog("RFCOMMPacket WARN: packet claims to be longer (\(payloadLength)) than it actually is (\(data.count - 2))")
                return
            }
            let payload: [UInt8] = Array(data[3...2 + payloadLength])
            self.payload = String(bytes: payload, encoding: .ascii)
        }
    }
}
