//
//  Driver.swift
//  AkkuLowLevel
//
//  Created by Jari on 15/10/2018.
//  Copyright © 2018 JARI.IO. All rights reserved.
//

import Foundation

struct Connection {
    var addr: (UInt8, UInt8, UInt8, UInt8, UInt8, UInt8)
    var connectionHandle: UInt16;
}

class Driver: NSObject, NSMachPortDelegate {
    var connection: io_connect_t = 0
    var mem_addr: mach_vm_address_t = 0;
    
    var connections: [Connection] = []
    var channels: [RFCOMMChannel] = []
    
    public func open () throws {
        // get driver
        let port = kIOMasterPortDefault;
        let service = IOServiceGetMatchingService(port, IOServiceMatching("IOBluetoothHCIController"))
        
        if (service == 0) {
            throw BluetoothHCIError.driverNotFound
        }
        
        // open connnection
        var ret = IOServiceOpen(service, mach_task_self_, UInt32((arc4random() << 8) + 1), &connection)
        IOObjectRelease(service)
        
        if (ret != kIOReturnSuccess) {
            throw BluetoothHCIError.failedToOpen(ioError: ret.string)
        }
        
        // map memory
        var mem_size: mach_vm_size_t = 0
        ret = IOConnectMapMemory64(self.connection, 0xffff, mach_task_self_, &self.mem_addr, &mem_size, 1)
        
        if (ret != kIOReturnSuccess) {
            throw BluetoothHCIError.mapMemoryFail(ioError: ret.string)
        }
    }
    
    func dump () throws {
        // instruct controller to dump log to our memory (I think? this is all undocumented. lol)
        var input: UInt64 = 0;
        var inputStruct = 1;
        
        var output: UInt64 = 0;
        var outputCnt: UInt32 = 1;
        var outputStruct = 0;
        var outputStructCnt = 0;
        
        let ret = IOConnectCallMethod(connection, 0, &input, 0, &inputStruct, 0, &output, &outputCnt, &outputStruct, &outputStructCnt)
        
        if (ret != kIOReturnSuccess) {
            throw BluetoothHCIError.methodCallFail(ioError: ret.string)
        }
    }
    
    func openDataQueue () throws -> Bool {
        let queuePointer = UnsafeMutablePointer<IODataQueueMemory>.init(bitPattern: Int(self.mem_addr));
        
        if queuePointer == nil {
            return false
        }
        
        repeat {
            let entryPointer = IODataQueuePeek(queuePointer)
            if entryPointer == nil {
                return false
            }
            
            var size: UInt32 = 0;
            IODataQueueDequeue(queuePointer, nil, &size)
            
            var offset = unsafeBitCast(entryPointer, to: Int.self)
            
            // skip over the entry's own memory...
            offset += MemoryLayout<IODataQueueEntry>.alignment
            
            // skip to the packet type (todo, research what this data actually contains)
            offset += 8;
            
            guard let ptr = UnsafeMutablePointer<UInt8>(bitPattern: offset),
                let packetType = PacketType(rawValue: ptr.pointee) else {
                    continue
            }
            
            let buffer = UnsafeMutableBufferPointer(start: UnsafeMutablePointer<UInt8>(bitPattern: offset + MemoryLayout<UInt8>.size), count: Int(size));
            
            switch packetType {
            case .HCI_EVENT:
                let packet = EventPacket(pointer: buffer)

                if packet.eventCode == 0x03 /* ConnectComplete */ && packet.status == 0x00 /* Success */ {
                    let conn = Connection(addr: packet.addr, connectionHandle: packet.connectionHandle)
                    print("Added connection, handle: \(packet.connectionHandle.hex)")
                    self.connections.append(conn)
                }
                
            case .RECV_ACL_DATA, .SENT_ACL_DATA:
                let packet = L2CapPacket(pointer: buffer, channels: self.channels)
                
                // FIXME: this stuff currently only works when the host device attempts a connection request
                // FIXME: not when the remote device does so.
                
                if packet.commandCode == 0x02 /* ConnectionRequest */ && packet.psm == 0x03 /* RFCOMM */ {
                    let connectionHandle = packet.flags & 0x0fff
                    
                    if let sourceCID = packet.sourceCID,
                        let connection = self.connections.first(where: { $0.connectionHandle == connectionHandle }) {
                        let channel = RFCOMMChannel(CID: packet.CID, sourceCID: sourceCID, connection: connection)
                        print("Added channel, CID: \(channel.CID.hex), sourceCID: \(sourceCID.hex), handle: \(channel.connection.connectionHandle.hex)")
                        self.channels.append(channel)
                    }
                    break
                }
                
                if packetType == .RECV_ACL_DATA && packet.payloadLength != nil && packet.payloadLength! > 0 {
                    // we got a rfcomm!!!!
                    debugPrint(packet.payload)
                }
                
            default:
                break;
            }
            
            offset += Int(size)
        } while IODataQueueDataAvailable(queuePointer)
        
        return true
    }

    public func handleMachMessage(_ msg: UnsafeMutableRawPointer) {
        print("abc")
    }
    
    func process () throws {
        var opened: Bool
        repeat {
            try self.dump()
            opened = try self.openDataQueue()
        } while opened
    }
    
    var port: NSMachPort?;
    var timer: Timer?;
    
    func waitForData () throws {
        let queuePointer = UnsafeMutablePointer<IODataQueueMemory>(bitPattern: Int(self.mem_addr));
        
        if queuePointer == nil {
            return
        }
        
        let port = NSMachPort()
        
        port.setDelegate(self)
        
        self.port = port
        
        self.timer = Timer(timeInterval: 5, repeats: true, block: { (_) in
            print("fucc")
        })
        RunLoop.current.add(self.timer!, forMode: .common)
        RunLoop.current.add(self.port!, forMode: .common)
        
        let ret = IODataQueueSetNotificationPort(queuePointer, port.machPort)
        
        if ret != kIOReturnSuccess {
            throw BluetoothHCIError.machPortInitFail(ioError: ret.string)
        }
    }
}
