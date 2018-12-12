//
//  CVarArg+hex.swift
//  Akku
//
//  Created by Jari on 28/10/2018.
//  Copyright © 2018 JARI.IO. All rights reserved.
//

import Foundation

extension CVarArg {
    var hex: String {
        get {
            return String(format: "%02X", self)
        }
    }
}
