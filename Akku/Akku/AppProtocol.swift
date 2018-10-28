//
//  AppProtocol.swift
//  SwiftPrivilegedHelperApplication
//
//  Created by Erik Berglund on 2018-10-01.
//  Copyright © 2018 Erik Berglund. All rights reserved.
//

import Foundation
import IOBluetooth

@objc(AppProtocol)
protocol AppProtocol {
    func reportBattery(address: BluetoothDeviceAddress, percentage: Int) -> Void
}
