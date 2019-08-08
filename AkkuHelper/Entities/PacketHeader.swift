//
//  PacketHeader.swift
//  Akku
//
//  Created by Jari on 08/08/2019.
//  Copyright © 2019 JARI.IO. All rights reserved.
//

import Foundation

struct PacketHeader {
    var length: UInt32;
    var ts_secs: UInt32;
    var ts_usecs: UInt32;
}
