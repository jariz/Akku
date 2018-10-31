//
//  Driver.swift
//  AkkuLowLevel
//
//  Created by Jari on 15/10/2018.
//  Copyright © 2018 JARI.IO. All rights reserved.
//

import Foundation
import IOBluetooth

class Driver: NSObject {
    
    // MARK: -
    // MARK: Initialisation
    
    init (appProtocol: AppProtocol?) {
        self.appProtocol = appProtocol
    }
    
    // MARK: -
    // MARK: Private IOKit variables
    
    fileprivate var connection: io_connect_t = 0
    fileprivate var mem_addr: mach_vm_address_t = 0;
    
    // MARK: -
    // MARK: Private variables
    
    fileprivate var timer: Timer?;
    fileprivate let appProtocol: AppProtocol?;
    
    // MARK: -
    // MARK: Detected RFCOMM channels and connections
    // NOTE: these connections/channels may be long gone, Akku does not track connection/channel closing events (yet).
    
    var connections: [Connection] = []
    var channels: [RFCOMMChannel] = []
    
    // MARK: -
    // MARK: Internal IOBluetoothHCIController communication
    
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
    
    fileprivate func dump () throws {
        // instruct controller to dump log to our memory
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
    
    fileprivate func openDataQueue () throws -> Bool {
        let queuePointer = UnsafeMutablePointer<IODataQueueMemory>(bitPattern: Int(self.mem_addr));
        
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
            
            // skip to the packet type (todo: research what this data actually contains)
            offset += 8;
            
            guard let ptr = UnsafeMutablePointer<UInt8>(bitPattern: offset),
                let packetType = PacketType(rawValue: ptr.pointee) else {
                    continue
            }
            
            // skip over packet type
            offset += MemoryLayout<UInt8>.size
            
            // build a buffer from the remaining packet
            var buffer = UnsafeMutableBufferPointer(start: UnsafeMutablePointer<UInt8>(bitPattern: offset), count: Int(size));
            
            switch packetType {
            case .HCI_EVENT:
                let packet = EventPacket(pointer: buffer)

                if packet.eventCode == kBluetoothHCIEventConnectionComplete && packet.status == 0x00 /* Success */ {
                    let conn = Connection(addr: BluetoothDeviceAddress(data: packet.addr!), connectionHandle: packet.connectionHandle!)
                    NSLog("Added connection, handle: \(packet.connectionHandle!.hex)")
                    self.connections.append(conn)
                }
                
            case .RECV_ACL_DATA, .SENT_ACL_DATA:
                let packet = L2CapPacket(pointer: buffer)
                
                // now that we've read the l2cap header, we can skip over it
                offset += L2CapPacket.length + 1
                buffer = UnsafeMutableBufferPointer(start: UnsafeMutablePointer<UInt8>(bitPattern: offset), count: Int(size));
                
                // FIXME: this stuff currently only works when the host device attempts a connection request
                // FIXME: not when the remote device does so.
                
                if let channel = channels.first(where: { $0.sourceCID == packet.CID }) {
                    // known RFCOMM channel, assume we're speaking RFCOMM
                    let rfcommPacket = RFCOMMPacket(pointer: buffer, parent: packet)
                    
                    if packetType == .RECV_ACL_DATA,
                        let payload = rfcommPacket.payload,
                        let battInfo = CommandParser.parseCommand(payload) {
                        NSLog("Got battery command: docked = \(String(describing: battInfo.docked)), percentage = \(String(describing: battInfo.percentage))")
                        
                        if let appProtocol = self.appProtocol {
                            if let docked = battInfo.docked {
                                appProtocol.reportDockChange(address: channel.connection.addr, docked: docked)
                            }
                            
                            if let percentage = battInfo.percentage {
                                appProtocol.reportBatteryChange(address: channel.connection.addr, percentage: percentage)
                            }
                        } else {
                            NSLog("Driver: No remote object found to send battery events to!")
                        }
                    }
                    
                } else {
                    // unknown channel, assume it's a command
                    let cmdPacket = L2CapCommand(pointer: buffer, parent: packet)
                    if let psm = cmdPacket.psm,
                        cmdPacket.commandCode == UInt8(kBluetoothL2CAPCommandCodeConnectionRequest.rawValue),
                        psm == kBluetoothL2CAPPSMRFCOMM {
                        let connectionHandle = packet.flags & 0x0fff

                        if let sourceCID = cmdPacket.sourceCID,
                            let connection = self.connections.first(where: { $0.connectionHandle == connectionHandle }) {
                            let channel = RFCOMMChannel(CID: packet.CID, sourceCID: sourceCID, connection: connection)
                            NSLog("Added channel, CID: \(channel.CID.hex), sourceCID: \(sourceCID.hex), handle: \(channel.connection.connectionHandle.hex)")
                            self.channels.append(channel)
                        }
                    }
                }
            default:
                break;
            }
            
            offset += Int(size)
        } while IODataQueueDataAvailable(queuePointer)
        
        return true
    }
    
    // MARK: -
    // MARK: Public interface
    
    func process () throws {
        var opened: Bool
        repeat {
            try self.dump()
            opened = try self.openDataQueue()
        } while opened
    }
    
    func poll () {
        self.timer = Timer(timeInterval: 5, repeats: true, block: { (_) in
            do {
                try self.process()
            } catch {
                NSLog(error.localizedDescription)
            }
        })
        
        OperationQueue.main.addOperation {
            RunLoop.current.add(self.timer!, forMode: .common)
        }
    }
}
