//
//  BluetoothPowerHandler.swift
//  Fatigue
//
//  Created by Mats Mollestad on 11/06/2021.
//

import Foundation
import Combine

struct BluetoothPowerHandler: PowerMeterHandler {
    
    var powerListner: AnyPublisher<PowerDeviceValue, Never> { valuesSubject.eraseToAnyPublisher() }
    private let valuesSubject = PassthroughSubject<PowerDeviceValue, Never>()
    
    let cadenceHandler = RevolutionHandler(
        maxEventValue: Double(UInt16.max) / pow(2, 10),
        maxRevolutionValue: Int(UInt16.max)
    )
    
    var characteristic: BluetoothCharacteristics = .cyclingPowerMeasurement
    
    func handle(values: Array<UInt8>) {
        
        guard values.count > 2 else { return }
        let flag = BluetoothPowerFlag(values: values)
        
        // First two used for flag
        var valueOffset: Int = 2
        
        var power = Int(values, index: &valueOffset, format: .format16)
        var powerBalance: PowerBalance?
        var rpm: Int?
        
        if flag.offsetCompensationIndicator {
            power = power * 2
        }
        
        if flag.isPowerBalancePresent {
            // Send the power data
            
            // Unit is in percentage with a resolution of 1/2.
            let balance = Double(
                values,
                index: &valueOffset,
                format: .format8,
                exponent: -1
            ) / 100
            powerBalance = PowerBalance(
                percentage: balance,
                reference: flag.powerBalanceReferance
            )
        }
        
        if flag.isAccumulatedTorquePresent {
            let accumulatedTorque = Double(
                values,
                index: &valueOffset,
                format: .format16,
                exponent: -5
            )
            print("Accumulated Torque: \(accumulatedTorque)")
        }
        
        if flag.isWheelRevolutionPresent {
            let wheelRevolutions = Int(values, index: &valueOffset, format: .format32)
            
            // Is a unit of 1/1024 sec
            let lastWheelEvent = Double(
                values,
                index: &valueOffset,
                format: .format16,
                exponent: -11
            )
            
            print("Wheep Rev: \(wheelRevolutions), last Event: \(lastWheelEvent)")
        }
        
        if flag.isCrankRevolutionPresent {
            let crankRevolutions = Int(values, index: &valueOffset, format: .format16)
            
            // Is a unit of 1/1024 sec
            let lastCrankEvent = Double(
                values,
                index: &valueOffset,
                format: .format16,
                exponent: -10
            )
            
            rpm = cadenceHandler.update(event: lastCrankEvent, revolutions: crankRevolutions)
        }
        
        if flag.isExtremeForceMagnitudePresent {
            /// FIXME: -- IS SIGNED VALUES
            let maximumForce = Int(values, index: &valueOffset, format: .format16)
            let minimumForce = Int(values, index: &valueOffset, format: .format16)
            print("Maximum Force: \(maximumForce), Minimum Force: \(minimumForce)")
        }
        
        if flag.isExtremeTorqueMagnitudePresent {
            /// FIXME: -- IS SIGNED VALUES
            let maximumTorque = Double(values, index: &valueOffset, format: .format16, exponent: -5)
            let minimumTorque = Double(values, index: &valueOffset, format: .format16, exponent: -5)
            print("Maximum Torque: \(maximumTorque), Minimum Torque: \(minimumTorque)")
        }
        
        if flag.isExtremeAnglePresent {
            // C5: When present, this field and the "Extreme Angles - Maximum Angle" field are always present as a pair and are concatenated into a UINT24 value (3 octets). As an example, if the Maximum Angle is 0xABC and the Minimum Angle is 0x123, the transmitted value is 0x123ABC.
            //
            // When observed with the front wheel to the right of the pedals, a value of 0 degrees represents the angle when the crank is in the 12 o'clock position and a value of 90 degrees represents the angle, measured clockwise, when the crank points towards the front wheel in a 3 o'clock position. The left crank sensor (if fitted) detects the 0° when the crank it is attached to is in the 12 o'clock position and the right sensor (if fitted) detects the 0° when the crank it is attached to is in its 12 o'clock position; thus, there is a constant 180° difference between the right crank and the left crank position signals
            let angles = Int(values, index: &valueOffset, format: .format24)
            print("Combined Angles (Min and Max): \(angles)")
        }
        
        if flag.isTopDeadSpotAnglePresent {
            let topDeadSpot = Int(values, index: &valueOffset, format: .format16)
            print("Top Dead Spot: \(topDeadSpot)")
        }
        
        if flag.isBottomDeadSpotAnglePresent {
            let bottomDeadSpot = Int(values, index: &valueOffset, format: .format16)
            print("Bottom Dead Spot: \(bottomDeadSpot)")
        }
        
        if flag.isAccumulatedEnergyPresent {
            let energy = Int(values, index: &valueOffset, format: .format16)
            print("Energy: \(energy)")
        }
        
        valuesSubject.send(
            .init(
                power: power,
                cadence: rpm,
                balence: powerBalance
            )
        )
    }
}


struct BluetoothPowerHandlerMock: PowerMeterHandler {
    
    var powerListner: AnyPublisher<PowerDeviceValue, Never> { valuesSubject.eraseToAnyPublisher() }
    private let valuesSubject = PassthroughSubject<PowerDeviceValue, Never>()
    
    var characteristic: BluetoothCharacteristics = .cyclingPowerMeasurement
    
    func handle(values: Array<UInt8>) {
        valuesSubject.send(PowerDeviceValue(
            power: 200 + Int.random(in: -20...20),
            cadence: 85 + Int.random(in: -5...10),
            balence: .init(percentage: 0.5 + Double.random(in: -0.1...0.1), reference: .left)
        ))
    }
}
