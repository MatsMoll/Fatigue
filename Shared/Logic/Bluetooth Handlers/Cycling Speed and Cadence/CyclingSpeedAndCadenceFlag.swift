//
//  CyclingSpeedAndCadenceFlag.swift
//  Fatigue
//
//  Created by Mats Mollestad on 17/06/2021.
//

import Foundation

struct CyclingSpeedAndCadenceFlag {
    let flags: [Bool]
    
    init(flag: UInt8) {
        self.flags = String(flag, radix: 2)
            .pad(toSize: 8)
            .reversed()
            .map { Int(String($0)) == 1 }
    }
    
    var isWheelRevolutionPresent: Bool { flags[0] }
    var isCadenceRevolutionPresent: Bool { flags[1] }
}
