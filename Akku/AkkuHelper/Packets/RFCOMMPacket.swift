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
        
        if data.count > 255 {
            log.warning("RFCOMMPacket: Data too big (> 255), skip!")
            return
        }
        
        if payloadLength > 0 {
            var offset = 3
            
            if data.count > 0, UInt8(data[offset]) != 65 {
                // (shitty) check if we encountered a credit based flow.
                // basically checks if we received a character that isn't A
                // if the next sequence doesn't match any known command the parser will fail anyway ¯\_(ツ)_/¯
                // we should've concluded this from the "dlc parameter negotiation" which is stuff we don't interpret at all right now.
                // but... meh. this isn't a friggin full-featured-bluetooth-stack and is probably "good enough".
                
                offset += 1
                payloadLength -= 1
                
                if payloadLength == 0 {
                    return
                }
            }
            
            if payloadLength > (data.count - offset) {
                log.warning("RFCOMMPacket: packet claims to be longer (\(payloadLength)) than it actually is (\(data.count - 2))")
                return
            }
            
            self.payload = String(data: data[offset...(Int(payloadLength - 1) + offset)], encoding: .ascii)
        }
    }
}
