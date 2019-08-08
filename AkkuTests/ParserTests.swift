//
//  AkkuTests.swift
//  AkkuTests
//
//  Created by Jari on 30/07/2019.
//  Copyright © 2019 JARI.IO. All rights reserved.
//

import XCTest
@testable import Akku
import IOBluetooth

class ParserTests: XCTestCase {
    let fileManager = FileManager.default
    
    func testPacketLog() {
        // most simple usecase, sends battery states seperately
        assertTestData("MOMENTUM 2 AEBT", "00:1b:66:7f:d3:15", 70)

        // a bit harder cause this device sends all the keypairs in a single command.
        assertTestData("BOSE QUIETCOMFORT", "4c:87:5d:0b:03:ea", 10)

//        // corrupted file test
//        assertTestData("Sennheiser HD 4.50 BTNC", "00:16:94:32:10:d6", 90)
//
//        // corrupted file. multiple headphones. complete chaos.
//        assertTestData("VEHO ZB-6", "20:18:01:bb:5c:42", 100)
    }
    
    func assertBatteryLevel (_ addr: inout BluetoothDeviceAddress, _ amount: Int, states: [BatteryInfo]) {
        // validate that there are any actual states
        XCTAssertTrue(states.contains { $0.percentage != nil}, "No battery percentages found")
        
        // validate that any states exist with the requested address
        XCTAssertTrue(states
            .compactMap { $0.connection }
            .contains { $0.addr.data == addr.data }
        , "No devices found with address \(IOBluetoothNSStringFromDeviceAddressColon(&addr)!)")
        
        // validate that none of the devices are docked
        XCTAssertTrue(states.contains { $0.docked == false })
        
        for state in states {
            if let percentage = state.percentage, let conn = state.connection {
                if conn.addr.data == addr.data {
                    XCTAssertEqual(percentage, amount, "Reported battery state did not match expected value (\(amount)%)")
                }
            }
        }
    }
    
    func assertTestData (_ baseName: String, _ addrString: String, _ amount: Int) {
        print("------")
        print("Testing data: \(baseName)")
        if let log = LogReader(pklgFile: fileManager.currentDirectoryPath + "/TestData/\(baseName).pklg") {
            var addr = BluetoothDeviceAddress(data: (0, 0, 0, 0, 0, 0))
            IOBluetoothNSStringToDeviceAddress(addrString, &addr)
            
            assertBatteryLevel(&addr, amount, states: log.parser.batteryInfos)
        } else {
            XCTFail("Unable to parse packetlog '\(baseName)'.")
            return
        }
    }
}
