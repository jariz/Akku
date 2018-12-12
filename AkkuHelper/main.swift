//
//  main.swift
//  SwiftPrivilegedHelper
//
//  Created by Erik Berglund on 2018-10-01.
//  Copyright © 2018 Erik Berglund. All rights reserved.
//

import Foundation
import Sentry
import SwiftyBeaver
import AppKit

let log = SwiftyBeaver.self

// fire up logging
let file = FileDestination()
let console = ConsoleDestination()
file.logFileURL = URL(fileURLWithPath: "/Library/Logs/AkkuHelper.log");
console.format = "$DHH:mm:ss$d $C$L - $M"
file.format = "$Ddd-MM-yyyy HH:mm:ss$d $L $F:$l - $M"
log.addDestination(file)
log.addDestination(console)

// fire up sentry
do {
    Client.shared = try Client(dsn: "https://7c90f578bae24cafb69e519f4a692036@sentry.io/1338198")
    try Client.shared?.startCrashHandler()
} catch let error {
    log.error(error)
}

let helper = Helper()
helper.run()
