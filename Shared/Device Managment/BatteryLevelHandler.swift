//
//  BatteryLevelHandler.swift
//  BatteryLevelHandler
//
//  Created by Mats Mollestad on 04/09/2021.
//

import Foundation
import Combine

protocol BatteryLevelHandler: BluetoothHandler {
    
    var batteryLevelChanged: AnyPublisher<Double, Never> { get }
}

struct BluetoothBatteryLevelHandler: BatteryLevelHandler {
    
    let characteristic: BluetoothCharacteristics = .batteryLevel
    
    var batteryLevelChanged: AnyPublisher<Double, Never> { batteryLevelSubject.eraseToAnyPublisher() }
    private let batteryLevelSubject = PassthroughSubject<Double, Never>()
    
    func handle(values: Array<UInt8>) {
        guard !values.isEmpty else { return }
        batteryLevelSubject.send(Double(Int(values, format: .format8)) / 100)
    }
}
