//
//  BluetoothPowerFlag.swift
//  Fatigue
//
//  Created by Mats Mollestad on 17/06/2021.
//

import Foundation

enum PowerBalanceReferance: Int, Codable {
    case unknown
    case left
}

enum AccumulatedTorqueSource {
    case wheelBased
    case crankBased
}

/// https://www.bluetooth.com/wp-content/uploads/Sitecore-Media-Library/Gatt/Xml/Characteristics/org.bluetooth.characteristic.cycling_power_measurement.xml
/// Different flags that can be active in a power meter
struct BluetoothPowerFlag {
    
    let flags: [Bool]
    
    init(values: [UInt8]) {
        self.flags = String(Int(values, format: .format16), radix: 2)
            .pad(toSize: 16)
            .reversed()
            .map { Int(String($0)) == 1 }
    }
    
    var isPowerBalancePresent: Bool { flags[0] }
    var powerBalanceReferance: PowerBalanceReferance { flags[1] ? .left : .unknown }
    
    var isAccumulatedTorquePresent: Bool { flags[2] }
    var accumulatedTorqueSource: AccumulatedTorqueSource { flags[3] ? .crankBased : .wheelBased }
    
    var isWheelRevolutionPresent: Bool { flags[4] }
    var isCrankRevolutionPresent: Bool { flags[5] }
    
    var isExtremeForceMagnitudePresent: Bool { flags[6] }
    var isExtremeTorqueMagnitudePresent: Bool { flags[7] }
    
    var isExtremeAnglePresent: Bool { flags[8] }
    
    var isTopDeadSpotAnglePresent: Bool { flags[9] }
    var isBottomDeadSpotAnglePresent: Bool { flags[10] }
    
    var isAccumulatedEnergyPresent: Bool { flags[11] }
    
    var offsetCompensationIndicator: Bool { flags[12] }
}
