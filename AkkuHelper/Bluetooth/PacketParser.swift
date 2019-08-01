//
//  PacketParser.swift
//  Akku
//
//  Created by Jari on 30/07/2019.
//  Copyright © 2019 JARI.IO. All rights reserved.
//

import Foundation
import IOBluetooth

class PacketParser {
    // MARK: Detected RFCOMM channels and connections
    
    var connections: [Connection] = []
    var connectionRequests: [ConnectionRequest] = []
    var channels: [RFCOMMChannel] = []
    var batteryInfos: [BatteryInfo] = []
    
    func read (_ offset: Int, _ size: UInt32) -> PacketType? {
        var offset = offset
        
        guard let ptr = UnsafeMutablePointer<UInt8>(bitPattern: offset),
            let packetType = PacketType(rawValue: ptr.pointee) else {
                return nil
        }
        
        // skip over packet type
        offset += MemoryLayout<UInt8>.size
        
        // build a buffer from the remaining packet
        var buffer = UnsafeMutableBufferPointer(start: UnsafeMutablePointer<UInt8>(bitPattern: offset), count: Int(size));
        
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
            buffer = UnsafeMutableBufferPointer(start: UnsafeMutablePointer<UInt8>(bitPattern: offset), count: Int(size));
            
            if let packet = packet, let channel = channels.first(where: { $0.sourceCID == packet.CID || $0.destinationCID == packet.CID }) {
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
        
        return packetType
    }
}
