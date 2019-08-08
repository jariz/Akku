//
//  LogReader.swift
//  Akku
//
//  Created by Jari on 30/07/2019.
//  Copyright © 2019 JARI.IO. All rights reserved.
//
//  Largely based on https://github.com/wireshark/wireshark/blob/master/wiretap/packetlogger.c
//  Copyright 2008-2009, Stephen Fisher
//

import Foundation
import SwiftyBeaver

class LogReader {
    let parser = PacketParser()
    
    init? (pklgFile: String) {
        let handle = FileHandle(forReadingAtPath: pklgFile)
        
        let info = ProcessInfo.processInfo
        let begin = info.systemUptime
        
        if var data = handle?.readDataToEndOfFile() {
            let targetPointer = UnsafeMutablePointer<UInt8>.allocate(capacity: data.count)
            data.copyBytes(to: targetPointer, count: data.count)
            let start = Int(bitPattern: targetPointer)
            
            var offset = 0
            var packets = 0
            var packetTypes = Dictionary<PacketType, Int>()
            
            repeat {
                let length = parser.read(start + offset)
                
                offset += MemoryLayout<PacketHeader>.size
                
                if let packetType = parser.lastPacketType {
                    if let val = packetTypes[packetType] {
                        packetTypes[packetType] = val + 1
                    } else {
                        packetTypes[packetType] = 1
                    }
                }
                
                // skip over the rest of the packet
                offset += Int(length - 8)
                packets += 1
                
            } while (offset < data.count)
            
            let diff = (info.systemUptime - begin)
            
            print("------")
            print("Parsed \(packets) packets in \((diff * 1000).rounded())ms")
            print(packetTypes
                .map({ entry in "\(entry.key): \(entry.value) packets" })
                .joined(separator: ", ")
            )
            
            targetPointer.deallocate()
            handle?.closeFile()
        } else {
            return nil
        }
    }
}
