//
//  L2CapPacket.swift
//  AkkuLowLevel
//
//  Created by Jari on 15/10/2018.
//  Copyright © 2018 JARI.IO. All rights reserved.
//

import Foundation

class L2CapPacket {
    init (pointer: UnsafeMutableBufferPointer<UInt8>, channels: [RFCOMMChannel]) {
        let data = Data(buffer: pointer)
        self.flags = data[0...1].withUnsafeBytes { $0.pointee }
        self.totalLength = data[2...3].withUnsafeBytes { $0.pointee }
        self.length = data[4...5].withUnsafeBytes { $0.pointee }
        self.CID = data[6...7].withUnsafeBytes { $0.pointee }

        let channel = channels.first(where: { $0.sourceCID == self.CID })
        
        if channel == nil {
            self.commandCode = data[8...8].withUnsafeBytes { $0.pointee }
            self.commandID = data[9...9].withUnsafeBytes { $0.pointee }
            self.commandLength = data[10...11].withUnsafeBytes { $0.pointee }
            self.psm = data[12...13].withUnsafeBytes { $0.pointee }
            
            if self.psm == 0x03 /* RFCOMM */ {
                let sourceCID: UInt16 = data[14...15].withUnsafeBytes { $0.pointee }
                self.sourceCID = sourceCID
            }
        } else {
            // we know this channel, so assume we're speaking rfcomm from now on
            self.address = data[8...8].withUnsafeBytes { $0.pointee }
            self.control = data[9...9].withUnsafeBytes { $0.pointee }
            var payloadLength: UInt8 = data[10...10].withUnsafeBytes({ $0.pointee })
            
            // https://github.com/wireshark/wireshark/blob/3a514caaf1e3b36eb284c3a566d489aba6df5392/epan/dissectors/packet-btrfcomm.c#L511
            payloadLength >>= 1
            
            if payloadLength > 0 {
                if payloadLength > data.count - 10 {
                    print("Akku WARN: packet claims to be longer (\(payloadLength)) than it actually is (\(data.count - 10))")
                    return
                }
                let payload: [UInt8] = Array(data[11...10 + payloadLength])
                self.payloadLength = payloadLength
                self.payload = String(bytes: payload, encoding: .ascii)
            }
        }
    }
    
    var flags: UInt16;
    var totalLength: UInt16;
    var length: UInt16;
    var CID: UInt16;
    
    // rfcomm only
    var address: UInt8?;
    var control: UInt8?;
    var payloadLength: UInt8?;
    var payload: String?;
    
    // l2cap command only
    var commandCode: UInt8?;
    var commandID: UInt8?;
    var commandLength: UInt16?;
    var psm: UInt16?;
    var sourceCID: UInt16?;
}
