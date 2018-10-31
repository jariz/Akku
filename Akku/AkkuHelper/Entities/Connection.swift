//
//  Connection.swift
//  Akku
//
//  Created by Jari on 31/10/2018.
//  Copyright © 2018 JARI.IO. All rights reserved.
//

import Foundation
import IOBluetooth

struct Connection {
    var addr: BluetoothDeviceAddress
    var connectionHandle: UInt16;
}
