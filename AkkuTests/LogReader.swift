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

struct PacketLoggerHeader {
    var length: UInt32;
    var ts_secs: UInt32;
    var ts_usecs: UInt32;
}

let MAX_PACKET_SIZE = 262144
let MIN_PACKET_SIZE = 8

class LogReader {
    let parser = PacketParser()
    
    func readHeader (bitPattern: Int) -> PacketLoggerHeader? {
        guard var header = UnsafePointer<PacketLoggerHeader>.init(bitPattern: bitPattern)?.pointee else {
            debugPrint("failed to read header")
            return nil
        }
        
        /*
         * If the upper 16 bits of the length are non-zero and the lower
         * 16 bits are zero, assume the file is little-endian.
         */
        if (header.length & 0x0000FFFF) == 0 && (header.length & 0xFFFF0000) != 0 {
            // Byte-swap the upper 16 bits (the lower 16 bits are zero, so we don't have to look at them).
            header.length = ((header.length >> 24) & 0xFF) | (((header.length >> 16) & 0xFF) << 8);
        }
        
        return header
    }
    
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
                guard let header = self.readHeader(bitPattern: start + offset) else {
                    return nil
                }
                
                // skip over header
                offset += MemoryLayout<PacketLoggerHeader>.size
                
                if header.length > MAX_PACKET_SIZE {
                    print("WARNING: header of packet #\(packets) too big")
                    continue
                } else {
                    if let packetType = parser.read(start + offset, header.length) {
                        if let val = packetTypes[packetType] {
                            packetTypes[packetType] = val + 1
                        } else {
                            packetTypes[packetType] = 1
                        }
                    }
                }
                
                if header.length < MIN_PACKET_SIZE {
                    print("packet length is too small")
                    return nil
                }
                
                
                // skip over the rest of the packet
                offset += Int(header.length - 8)
                
                packets += 1
                
            } while (offset < data.count)
            
            let diff = (info.systemUptime - begin)
            
            print("------")
            print("Parsed \(packets) packets in \((diff * 1000).rounded())ms")
            print(packetTypes
                .map({ entry in "\(entry.key): \(entry.value) packets"})
                .joined(separator: ", ")
            )
            
            targetPointer.deallocate()
            handle?.closeFile()
        } else {
            return nil
        }
    }
}
