//
//  AppProtocol.swift
//  SwiftPrivilegedHelperApplication
//
//  Created by Erik Berglund on 2018-10-01.
//  Copyright © 2018 Erik Berglund. All rights reserved.
//

import Foundation

@objc(AppProtocol)
protocol AppProtocol {
    func log(stdOut: String) -> Void
    func log(stdErr: String) -> Void
}
