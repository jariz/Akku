//
//  ConnectionRequest.swift
//  Akku
//
//  Created by Jari on 21/11/2018.
//  Copyright © 2018 JARI.IO. All rights reserved.
//

import Foundation
import IOBluetooth

struct ConnectionRequest {
    let commandID: UInt8;
    let connection: Connection;
}
