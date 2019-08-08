//
//  BluetoothHCIError.swift
//  AkkuLowLevel
//
//  Created by Jari on 15/10/2018.
//  Copyright © 2018 JARI.IO. All rights reserved.
//

public enum BluetoothHCIError: Error {
    // IOBluetoothHCIController driver not found
    case driverNotFound
    
    // Failed to open a connection to the IOBluetoothHCIController driver
    case failedToOpen(ioError: String)
    
    // Failed to map memory from driver
    case mapMemoryFail(ioError: String)
    
    // Failed to call method on driver
    case methodCallFail(ioError: String)
    
    // Failed to read from data queue
    case dataQueueReadFail(ioError: String)
    
    // Failed to initialize data queue
    case dataQueueInitFail
    
    // Failed to initialize data queue
    case machPortInitFail(ioError: String)
}
