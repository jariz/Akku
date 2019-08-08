//
//  PacketParser.swift
//  Akku
//
//  Created by Jari on 30/07/2019.
//  Copyright © 2019 JARI.IO. All rights reserved.
//

import Foundation
import IOBluetooth

let MAX_PACKET_SIZE = 262144
let MIN_PACKET_SIZE = 8

class PacketParser {
    // MARK: Detected RFCOMM channels and connections
    
    var connections: [Connection] = []
    var connectionRequests: [ConnectionRequest] = []
    var channels: [RFCOMMChannel] = []
    var batteryInfos: [BatteryInfo] = []
    
    var lastPacketType: PacketType?
    
    func read (_ offset: Int) -> UInt32 {
        var offset = offset
        lastPacketType = nil
        
        guard var header = UnsafePointer<PacketHeader>(bitPattern: offset)?.pointee else {
            return 0
        }
        
        /*
         * If the upper 16 bits of the length are non-zero and the lower
         * 16 bits are zero, assume the file is little-endian.
         */
        if (header.length & 0x0000FFFF) == 0 && (header.length & 0xFFFF0000) != 0 {
            // Byte-swap the upper 16 bits (the lower 16 bits are zero, so we don't have to look at them).
            header.length = ((header.length >> 24) & 0xFF) | (((header.length >> 16) & 0xFF) << 8);
        }
        
        if header.length < MIN_PACKET_SIZE {
            print("packet length is too small")
            return header.length
        }
        
        if header.length > MAX_PACKET_SIZE {
            print("packet length too big")
            return header.length
        }
        
        // skip over header
        offset += MemoryLayout<PacketHeader>.size
        
        guard let ptr = UnsafeMutablePointer<UInt8>(bitPattern: offset),
            let packetType = PacketType(rawValue: ptr.pointee) else {
                return header.length
        }
        
        // skip over packet type
        offset += MemoryLayout<UInt8>.size
        
        // build a buffer from the remaining packet
        var buffer = UnsafeMutableBufferPointer(start: UnsafeMutablePointer<UInt8>(bitPattern: offset), count: Int(header.length));
        
        switch packetType {
        case .HCI_EVENT:
            let packet = EventPacket(pointer: buffer)
            
            if let packet = packet, packet.eventCode == kBluetoothHCIEventConnectionComplete && packet.status == 0x00 /* Success */ {
                let conn = Connection(addr: BluetoothDeviceAddress(data: packet.addr!), connectionHandle: packet.connectionHandle!)
                print("Added connection, handle: \(packet.connectionHandle!.hex)")
                self.connections.append(conn)
            }
            
        case .RECV_ACL_DATA, .SENT_ACL_DATA:
            let packet = L2CapPacket(pointer: buffer)
            
            // now that we've read the l2cap header, we can skip over it
            offset += L2CapPacket.length
            buffer = UnsafeMutableBufferPointer(start: UnsafeMutablePointer<UInt8>(bitPattern: offset), count: Int(header.length));
            
            if let packet = packet, let channel = channels.first(where: {
                packetType == .RECV_ACL_DATA ? $0.sourceCID == packet.CID : $0.destinationCID == packet.CID
            }) {
                // known RFCOMM channel, assume we're speaking RFCOMM
                let rfcommPacket = RFCOMMPacket(pointer: buffer, parent: packet)
                
                if packetType == .RECV_ACL_DATA,
                    let payload = rfcommPacket?.payload,
                    var battInfo = CommandParser.parsePayload(payload) {
                    battInfo.connection = channel.connection

                    print("Got battery command: docked = \(String(describing: battInfo.docked)), percentage = \(String(describing: battInfo.percentage))")
                    
                    batteryInfos.append(battInfo)
                }
                
            } else if let packet = packet {
                // unknown channel, assume it's a command
                let cmdPacket = L2CapCommand(pointer: buffer, parent: packet)
                let connectionHandle = packet.flags & 0x0fff
                
                if let cmdPacket = cmdPacket {
                    if cmdPacket.commandCode == UInt8(kBluetoothL2CAPCommandCodeConnectionRequest.rawValue),
                        let psm = cmdPacket.psm,
                        psm == kBluetoothL2CAPPSMRFCOMM {
                        if let connection = self.connections.first(where: { $0.connectionHandle == connectionHandle }) {
                            let request = ConnectionRequest(commandID: cmdPacket.commandID, connection: connection)
                            print("Got connection request, ID: \(request.commandID.hex), handle: \(request.connection.connectionHandle.hex)")
                            self.connectionRequests.append(request)
                        }
                    } else if cmdPacket.commandCode == UInt8(kBluetoothL2CAPCommandCodeConnectionResponse.rawValue),
                        let result = cmdPacket.result,
                        result == UInt16(kBluetoothL2CAPConnectionResultSuccessful.rawValue),
                        let sourceCID = cmdPacket.sourceCID,
                        let destinationCID = cmdPacket.destinationCID,
                        let connection = self.connections.first(where: { $0.connectionHandle == connectionHandle }) {
                        
                        // check if this is a connection request attempt that we've heard of...
                        if let requestIndex = self.connectionRequests.firstIndex(where: { $0.commandID == cmdPacket.commandID && $0.connection.connectionHandle == connectionHandle }) {
                            self.connectionRequests.remove(at: requestIndex)
                            let channel = RFCOMMChannel(CID: packet.CID, sourceCID: sourceCID, destinationCID: destinationCID, connection: connection)
                            print("Added channel, CID: \(channel.CID.hex), sourceCID: \(sourceCID.hex), destinationCID: \(destinationCID.hex) handle: \(channel.connection.connectionHandle.hex)")
                            self.channels.append(channel)
                        }
                    }
                }
            }
        default:
            break
        }
        
        lastPacketType = packetType
        return header.length
    }
}
