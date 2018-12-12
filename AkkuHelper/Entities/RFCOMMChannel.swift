//
//  Channel.swift
//  AkkuLowLevel
//
//  Created by Jari on 18/10/2018.
//  Copyright © 2018 JARI.IO. All rights reserved.
//

import Foundation

struct RFCOMMChannel {
    var CID: UInt16;
    var sourceCID: UInt16;
    var destinationCID: UInt16;
    var connection: Connection;
}
