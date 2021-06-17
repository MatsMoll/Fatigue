//
//  BluetoothHeartRateFlag.swift
//  Fatigue
//
//  Created by Mats Mollestad on 17/06/2021.
//

import Foundation

enum HeartRateSensorStatus: Int {
    case notSupported
    case supportedButNoContactDetected
    case supportedWithDetectedContact
}

/// https://www.bluetooth.com/wp-content/uploads/Sitecore-Media-Library/Gatt/Xml/Characteristics/org.bluetooth.characteristic.heart_rate_measurement.xml
/// Flags representing the different heart rate values
struct BluetoothHeartRateFlag {
    
    let flags: [Bool]
    
    init(values: [UInt8]) {
        self.flags = String(Int(values, format: .format8), radix: 2)
            .pad(toSize: 8)
            .reversed()
            .map { Int(String($0)) == 1 }
    }
    
    var heartRateFormat: ArrayIntegerFormat {
        if flags[0] {
            return .format16
        } else {
            return .format8
        }
    }
    
    var status: HeartRateSensorStatus {
        if flags[2] {
            // Is value 0 and 1
            return .notSupported
        } else if flags[1] {
            // Is value 3
            return .supportedWithDetectedContact
        } else {
            // Is value 2
            return .supportedButNoContactDetected
        }
    }
    
    var isEnergyExpendedPresent: Bool { flags[3] }
    
    var isRRIntervalsPresent: Bool { flags[4] }
}
