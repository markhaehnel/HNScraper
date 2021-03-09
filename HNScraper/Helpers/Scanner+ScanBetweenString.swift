//
//  Scanner+ScanBetweenString.swift
//  HNScraper
//
//  Created by Stéphane Sercu on 29/09/17.
//  Copyright © 2017 Stéphane Sercu. All rights reserved.
//

import Foundation
extension Scanner {
    func scanBetweenString(stringA: String, stringB: String, into: AutoreleasingUnsafeMutablePointer<NSString?>?) {
        var trash: NSString? = ""
        scanUpTo(stringA, into: &trash)
        scanString(stringA, into: &trash)
        scanUpTo(stringB, into: into)
    }
}
