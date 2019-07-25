//
//  L2CapPacket.swift
//  AkkuLowLevel
//
//  Created by Jari on 15/10/2018.
//  Copyright © 2018 JARI.IO. All rights reserved.
//

import Foundation

class L2CapPacket {
    
    // MARK: -
    // MARK: Public static constants
    
    static let length = 8
    
    // MARK: -
    // MARK: Public constants
    
    let flags: UInt16;
    let totalLength: UInt16;
    let length: UInt16;
    let CID: UInt16;
    
    // MARK: -
    // MARK: Initializers
    
    init? (pointer: UnsafeMutableBufferPointer<UInt8>) {
        let data = Data(buffer: pointer)
        
        if data.count < L2CapPacket.length {
            return nil
        }
        
        self.flags = data[0...1].withUnsafeBytes { $0.pointee }
        self.totalLength = data[2...3].withUnsafeBytes { $0.pointee }
        self.length = data[4...5].withUnsafeBytes { $0.pointee }
        self.CID = data[6...7].withUnsafeBytes { $0.pointee }
    }
}
