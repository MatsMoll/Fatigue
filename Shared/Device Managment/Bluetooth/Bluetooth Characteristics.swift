//
//  Bluetooth Characteristics.swift
//  Bluetooth Characteristics
//
//  Created by Mats Mollestad on 04/09/2021.
//

import Foundation
import CoreBluetooth

struct BluetoothCharacteristics: Identifiable, Hashable, Equatable {
    
    let id: String
    var uuid: CBUUID { CBUUID(string: id) }
    
    static let batteryLevel = BluetoothCharacteristics(id: "2A19")
    
    static let heartRateMeasurement = BluetoothCharacteristics(id: "2A37")
    static let heartRateControlPoint = BluetoothCharacteristics(id: "2A39")
    
    static let cyclingSpeedAndCadenceMeasurement = BluetoothCharacteristics(id: "2A5B")
    static let cyclingSpeedAndCadenceFeature = BluetoothCharacteristics(id: "2A5C")
    
    static let cyclingPowerMeasurement = BluetoothCharacteristics(id: "2A63")
    static let cyclingPowerVector = BluetoothCharacteristics(id: "2A64")
}

/// A protocol for defining how a Bluetooth signal should be handled
protocol BluetoothHandler {
    func handle(values: Array<UInt8>)
    
    var characteristic: BluetoothCharacteristics { get }
}

struct BluetoothValue {
    let characteristic: BluetoothCharacteristics
    let values: [UInt8]
}
