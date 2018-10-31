//
//  L2CapCommand.swift
//  Akku
//
//  Created by Jari on 31/10/2018.
//  Copyright © 2018 JARI.IO. All rights reserved.
//

import Foundation

class L2CapCommand {
    
    // MARK: -
    // MARK: Private constants
    
    private let parent: L2CapPacket
    
    // MARK: -
    // MARK: Public constants
    
    let commandCode: UInt8;
    let commandID: UInt8;
    let commandLength: UInt16;
    
    // MARK: Public connection request command specific fields
    
    var psm: UInt16?;
    var sourceCID: UInt16?;
    
    // MARK: -
    // MARK: Initializers
    
    init (pointer: UnsafeMutableBufferPointer<UInt8>, parent: L2CapPacket) {
        self.parent = parent
        
        let data = Data(buffer: pointer)
        
        self.commandCode = data[0...0].withUnsafeBytes { $0.pointee }
        self.commandID = data[1...1].withUnsafeBytes { $0.pointee }
        self.commandLength = data[2...3].withUnsafeBytes { $0.pointee }
        
        if self.commandCode == 0x02 /* Connection Request */ {
            let psm: UInt16 = data[4...5].withUnsafeBytes { $0.pointee }
            let sourceCID: UInt16 = data[6...7].withUnsafeBytes { $0.pointee }
            self.psm = psm
            self.sourceCID = sourceCID
        }
    }
}
