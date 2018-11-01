//
//  NSImage+tinting.swift
//  Akku
//
//  Created by Jari on 01/11/2018.
//  Copyright © 2018 JARI.IO. All rights reserved.
//

import Foundation
import Cocoa

// thanks homecoffeecode.com
// http://homecoffeecode.com/nsimage-tinted-as-easily-as-a-uiimage/

extension NSImage {
    func tinting(with tintColor: NSColor) -> NSImage {
        guard let cgImage = self.cgImage(forProposedRect: nil, context: nil, hints: nil) else { return self }
        
        return NSImage(size: size, flipped: false) { bounds in
            guard let context = NSGraphicsContext.current?.cgContext else { return false }
            tintColor.set()
            context.clip(to: bounds, mask: cgImage)
            context.fill(bounds)
            return true
        }
    }
}
