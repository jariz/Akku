//
//  EventPacket.swift
//  AkkuLowLevel
//
//  Created by Jari on 15/10/2018.
//  Copyright © 2018 JARI.IO. All rights reserved.
//

import Foundation

struct EventPacket {
    init (pointer: UnsafeMutableBufferPointer<UInt8>) {
        let data = Data(buffer: pointer)
        self.eventCode = data[0...0].withUnsafeBytes { $0.pointee }
        self.parameterLength = data[1...1].withUnsafeBytes { $0.pointee }
        self.status = data[2...2].withUnsafeBytes { $0.pointee }
        self.connectionHandle = data[3...4].withUnsafeBytes { $0.pointee }
        self.addr = data[5...10].withUnsafeBytes { $0.pointee }
        self.linkType = data[11...11].withUnsafeBytes { $0.pointee }
        self.encryptionMode = data[12...12].withUnsafeBytes { $0.pointee }
    }
    
    var eventCode: UInt8;
    var parameterLength: UInt8;
    var status: UInt8;
    var connectionHandle: UInt16;
    var addr: (UInt8, UInt8, UInt8, UInt8, UInt8, UInt8);
    var linkType: UInt8;
    var encryptionMode: UInt8;
    
}
