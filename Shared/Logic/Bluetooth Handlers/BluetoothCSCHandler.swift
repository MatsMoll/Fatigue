//
//  BluetoothCSCHandler.swift
//  Fatigue
//
//  Created by Mats Mollestad on 13/06/2021.
//

import Foundation
import Combine

protocol CyclingSpeedAndCadenceHandler {
    var cadencePublisher: AnyPublisher<Int, Never> { get }
    var speedPublisher: AnyPublisher<Int, Never> { get }
}

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

struct BluetoothCSCHandler: CyclingSpeedAndCadenceHandler, BluetoothHandler {
    
    var cadencePublisher: AnyPublisher<Int, Never> { cadenceSubject.eraseToAnyPublisher() }
    
    var speedPublisher: AnyPublisher<Int, Never> { speedSubject.eraseToAnyPublisher() }
    
    private let speedSubject = PassthroughSubject<Int, Never>()
    private let cadenceSubject = PassthroughSubject<Int, Never>()
    
    private let speedHandler = RevolutionHandler(
        maxEventValue: Double(UInt16.max) / pow(2, 11),
        maxRevolutionValue: Int(UInt32.max)
    )
    private let cadenceHandler = RevolutionHandler(
        maxEventValue: Double(UInt16.max) / pow(2, 10),
        maxRevolutionValue: Int(UInt16.max)
    )
    
    let characteristicID: String = ""
    
    func handle(values: Array<UInt8>) {
        let flags = CyclingSpeedAndCadenceFlag(flag: values[0])
        
        var valueOffset = 1
        
        if flags.isWheelRevolutionPresent {
            let wheelRevolutions = Int(values, index: &valueOffset, format: .format32)
            
            // Is a unit of 1/1024 sec
            let lastWheelEvent = Double(
                values,
                index: &valueOffset,
                format: .format16,
                exponent: -11
            )
            
            speedSubject.send(
                speedHandler.update(event: lastWheelEvent, revolutions: wheelRevolutions)
            )
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
            
            cadenceSubject.send(
                cadenceHandler.update(event: lastCrankEvent, revolutions: crankRevolutions)
            )
        }
    }
}
