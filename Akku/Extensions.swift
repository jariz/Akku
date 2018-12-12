//
//  NotificationNames.swift
//  Akku
//
//  Created by Jari on 26/11/2018.
//  Copyright © 2018 JARI.IO. All rights reserved.
//

import Foundation
import Cocoa

extension NSNotification.Name {
    static let InstallerHeightChange = Notification.Name("HelperInstallerHeightChange")
}

extension Int {
    init?(_ value: String?) {
        guard let value = value else { return nil }
        self.init(value)
    }
}
