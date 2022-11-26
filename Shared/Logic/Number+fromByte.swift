//
//  Number+fromByte.swift
//  Fatigue
//
//  Created by Mats Mollestad on 17/06/2021.
//

import Foundation
import OSLog

extension String {
    
    func pad(toSize: Int) -> String {
        var padded = self
        guard toSize > self.count else { return self }
        for _ in 0..<(toSize - self.count) {
            padded = "0" + padded
            
        }
        return padded
    }
}

enum ArrayIntegerFormat: Int {
    case format8 = 1
    case format16 = 2
    case format24 = 3
    case format32 = 4
}

extension Int {
    init(value: UInt8, exponent: UInt8) {
        self = Int(value) + Int(exponent) * 256
    }
    
    init(_ values: Array<UInt8>, index: inout Int, format: ArrayIntegerFormat, exponent: UInt = 0) {
        // Raw value is the exponent
        self = 0
        guard index + format.rawValue < values.count else {
            let indexString = "\(index)"
            Logger().critical("Unable to decode int from \(values, privacy: .public), bytes: \(format.rawValue, privacy: .public), index: \(indexString, privacy: .public)")
            return
        }
        for i in 0..<format.rawValue {
            self += Int(values[index + i]) * Int(pow(Double(UInt8.max), Double(i)))
        }
        self = self * Int(pow(2, Double(exponent)))
        index += format.rawValue
    }
    
    init(_ values: Array<UInt8>, format: ArrayIntegerFormat, exponent: UInt = 0) {
        // Raw value is the exponent
        self = 0
        for i in 0..<format.rawValue {
            self += Int(values[i]) * Int(pow(Double(UInt8.max), Double(i)))
        }
        self = self * Int(pow(2, Double(exponent)))
    }
}

extension Double {
    init(_ values: Array<UInt8>, index: inout Int, format: ArrayIntegerFormat, exponent: Int = 0) {
        // Raw value is the exponent
        self = 0
        for i in 0..<format.rawValue {
            self += Double(values[index + i]) * pow(Double(UInt8.max), Double(i))
        }
        self = self * pow(2, Double(exponent))
        index += format.rawValue
    }
}
