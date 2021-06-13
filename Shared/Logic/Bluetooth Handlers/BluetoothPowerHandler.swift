//
//  BluetoothPowerHandler.swift
//  Fatigue
//
//  Created by Mats Mollestad on 11/06/2021.
//

import Foundation
import Combine

protocol PowerHandler {
    var powerPublisher: AnyPublisher<Int, Never> { get }
    var cadencePublisher: AnyPublisher<Int, Never> { get }
}

enum PowerBalanceReferance {
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
        self.flags = String(Int(values, index: 0, format: .format16), radix: 2)
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

struct BluetoothPowerHandler: PowerHandler, BluetoothHandler {
    
    var powerPublisher: AnyPublisher<Int, Never> { powerSubject.eraseToAnyPublisher() }
    var cadencePublisher: AnyPublisher<Int, Never> { cadenceSubject.eraseToAnyPublisher() }
    
    private let powerSubject = PassthroughSubject<Int, Never>()
    private let cadenceSubject = PassthroughSubject<Int, Never>()
    
    private let cadenceHandler = RevolutionHandler()
    
    var characteristicID: String = "2A63"
    
    func handle(values: Array<UInt8>) {
        
        guard values.count > 2 else { return }
        let flag = BluetoothPowerFlag(values: values, index: 0)
        
        
//        let flag = Int(values[0]) + Int(values[1]) * 256
        
        // First two used for flag
        var valueOffset: Int = 2
        
        let power = Int(values, index: valueOffset, format: .format16)
        valueOffset += 2
        powerSubject.send(power)
        
        if flag.isPowerBalancePresent {
            // Unit is in percentage with a resolution of 1/2.
            let balance = Int(values, index: valueOffset, format: .format8)
            print("Balance: \(balance)")
            valueOffset += 1
        }
        
        if flag.isAccumulatedTorquePresent {
            let accumulatedTorque = Int(values, index: valueOffset, format: .format16)
            valueOffset += 2
            print("Accumulated Torque: \(accumulatedTorque)")
        }
        
        if flag.isWheelRevolutionPresent {
            let wheelRevolutions = Int(values, index: valueOffset, format: .format32)
            valueOffset += 4
            
            // Is a unit of 1/1024 sec
            let lastWheelEvent = Int(values, index: valueOffset, format: .format16)
            valueOffset += 2
            
            print("Wheep Rev: \(wheelRevolutions), last Event: \(lastWheelEvent)")
        }
        
        if flag.isCrankRevolutionPresent {
            let crankRevolutions = Int(values, index: valueOffset, format: .format16)
            valueOffset += 2
            
            // Is a unit of 1/1024 sec
            let lastCrankEvent = Int(values, index: valueOffset, format: .format16)
            valueOffset += 2
            
            let rpm = cadenceHandler.update(event: lastCrankEvent, revolutions: crankRevolutions)
            cadenceSubject.send(rpm)
        }
        
        if flag.isExtremeForceMagnitudePresent {
            /// FIXME: -- IS SIGNED VALUES
            let maximumForce = Int(values, index: valueOffset, format: .format16)
            valueOffset += 2
            let minimumForce = Int(values, index: valueOffset, format: .format16)
            valueOffset += 2
            print("Maximum Force: \(maximumForce), Minimum Force: \(minimumForce)")
        }
        
        if flag.isExtremeTorqueMagnitudePresent {
            /// FIXME: -- IS SIGNED VALUES
            let maximumTorque = Int(values, index: valueOffset, format: .format16)
            valueOffset += 2
            let minimumTorque = Int(values, index: valueOffset, format: .format16)
            valueOffset += 2
            print("Maximum Torque: \(maximumTorque), Minimum Torque: \(minimumTorque)")
        }
        
        if flag.isExtremeAnglePresent {
            // C5: When present, this field and the "Extreme Angles - Maximum Angle" field are always present as a pair and are concatenated into a UINT24 value (3 octets). As an example, if the Maximum Angle is 0xABC and the Minimum Angle is 0x123, the transmitted value is 0x123ABC.
            let angles = Int(values, index: valueOffset, format: .format24)
            valueOffset += 3
            print("Combined Angles (Min and Max): \(angles)")
        }
        
        if flag.isTopDeadSpotAnglePresent {
            let topDeadSpot = Int(values, index: valueOffset, format: .format16)
            valueOffset += 2
            print("Top Dead Spot: \(topDeadSpot)")
        }
        
        if flag.isBottomDeadSpotAnglePresent {
            let bottomDeadSpot = Int(values, index: valueOffset, format: .format16)
            valueOffset += 2
            print("Bottom Dead Spot: \(bottomDeadSpot)")
        }
        
        if flag.isAccumulatedEnergyPresent {
            let energy = Int(values, index: valueOffset, format: .format16)
            valueOffset += 2
            print("Energy: \(energy)")
        }
    }
}
