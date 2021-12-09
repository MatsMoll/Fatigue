//
//  CoreBluetoothDeviceConnector.swift
//  CoreBluetoothDeviceConnector
//
//  Created by Mats Mollestad on 04/09/2021.
//

import Foundation
import CoreBluetooth
import Combine

class CoreBluetoothDeviceConnector: NSObject, CBPeripheralDelegate {
    
    let supportedCharacteristics: Set<CBUUID>
    
    var valuePublisher: AnyPublisher<BluetoothValue, Never> { valueSubject.eraseToAnyPublisher() }
    private let valueSubject = PassthroughSubject<BluetoothValue, Never>()
    
    init(supportedCharacteristics: Set<BluetoothCharacteristics>) {
        self.supportedCharacteristics = Set(supportedCharacteristics.map(\.uuid))
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let services = peripheral.services else { return }
        for service in services {
            peripheral.discoverCharacteristics(nil, for: service)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard
            let characteristics = service.characteristics
        else { return }
        for char in characteristics {
            guard supportedCharacteristics.contains(char.uuid) else { continue }
            if char.properties.contains(.read) {
                peripheral.readValue(for: char)
                print("Single Read")
            } else if char.properties.contains(.notify) {
                peripheral.setNotifyValue(true, for: char)
                print("Notify")
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        guard let data = characteristic.value else { return }
        valueSubject.send(
            .init(
                characteristic: .init(id: characteristic.uuid.uuidString),
                values: [UInt8].init(data)
            )
        )
    }
}
