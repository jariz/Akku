//
//  ExtensionsNSTextView.swift
//  SwiftPrivilegedHelperApplication
//
//  Created by Erik Berglund on 2018-10-01.
//  Copyright © 2018 Erik Berglund. All rights reserved.
//

import Cocoa

extension NSTextView {
    func appendText(_ text: String) {
        DispatchQueue.main.async {
            let attrDict = [NSAttributedString.Key.font: NSFont.systemFont(ofSize: NSFont.smallSystemFontSize)]
            let astring = NSAttributedString(string: "\(text)\n", attributes: attrDict)
            self.textStorage?.append(astring)
            let loc = self.string.lengthOfBytes(using: String.Encoding.utf8)
            let range = NSRange(location: loc, length: 0)
            self.scrollRangeToVisible(range)
        }
    }
}
