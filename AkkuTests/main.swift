//
//  main.swift
//  AkkuTests
//
//  Created by Jari on 30/07/2019.
//  Copyright © 2019 JARI.IO. All rights reserved.
//

import Foundation
import SwiftyBeaver

let log = SwiftyBeaver.self

// fire up logging
let console = ConsoleDestination()
console.format = "$DHH:mm:ss$d $C$L - $M"
log.addDestination(console)

log.info("ya")
