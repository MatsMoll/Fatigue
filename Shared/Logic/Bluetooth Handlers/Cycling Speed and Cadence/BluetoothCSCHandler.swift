//
//  BluetoothCSCHandler.swift
//  Fatigue
//
//  Created by Mats Mollestad on 13/06/2021.
//

import Foundation
import Combine

struct CSCDeviceValue {
    let cadence: Int?
    let speed: Int?
}

protocol CyclingSpeedAndCadenceHandler {
    var cyclingAndSpeedListner: AnyPublisher<CSCDeviceValue, Never> { get }
}

struct BluetoothCSCHandler: CyclingSpeedAndCadenceHandler, BluetoothHandler {
    
    var cyclingAndSpeedListner: AnyPublisher<CSCDeviceValue, Never> { cyclingAndSpeedSubject.eraseToAnyPublisher() }
    
    private let cyclingAndSpeedSubject = PassthroughSubject<CSCDeviceValue, Never>()
    
    private let speedHandler = RevolutionHandler(
        maxEventValue: Double(UInt16.max) / pow(2, 11),
        maxRevolutionValue: Int(UInt32.max)
    )
    private let cadenceHandler = RevolutionHandler(
        maxEventValue: Double(UInt16.max) / pow(2, 10),
        maxRevolutionValue: Int(UInt16.max)
    )
    
    let characteristic: BluetoothCharacteristics = .cyclingSpeedAndCadenceMeasurement
    
    func handle(values: Array<UInt8>) {
        let flags = CyclingSpeedAndCadenceFlag(flag: values[0])
        
        var valueOffset = 1
        var speed: Int?
        var cadence: Int?
        
        if flags.isWheelRevolutionPresent {
            let wheelRevolutions = Int(values, index: &valueOffset, format: .format32)
            
            // Is a unit of 1/1024 sec
            let lastWheelEvent = Double(
                values,
                index: &valueOffset,
                format: .format16,
                exponent: -11
            )
            
            speed = speedHandler.update(event: lastWheelEvent, revolutions: wheelRevolutions)
        }
        
        // Cadence revolution is present
        if flags.isCadenceRevolutionPresent {
            let crankRevolutions = Int(values, index: &valueOffset, format: .format16)
            
            // Is a unit of 1/1024 sec
            let lastCrankEvent = Double(
                values,
                index: &valueOffset,
                format: .format16,
                exponent: -10
            )
            
            cadence = cadenceHandler.update(event: lastCrankEvent, revolutions: crankRevolutions)
        }
        
        cyclingAndSpeedSubject.send(
            CSCDeviceValue(
                cadence: cadence,
                speed: speed
            )
        )
    }
}
