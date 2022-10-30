//
//  Device Wrapper.swift
//  Device Wrapper
//
//  Created by Mats Mollestad on 04/09/2021.
//

import Foundation
import Combine

/// A Protocol making it easier to wrap around a device and transfomr the
/// Recived values into a higher level and more userfriendly values
protocol BluetoothDeviceWrapper: BluetoothDevice {
    var device: BluetoothDevice { get }
    var handlers: [BluetoothHandler] { get }
    
    func handle(values: BluetoothValue)
}

extension BluetoothDeviceWrapper {
    var id: UUID { device.id }
    var name: String { device.name }
    
    var unableToConnect: AnyPublisher<Device, Never> { device.unableToConnect }
    var didConnect: AnyPublisher<Device, Never> { device.didConnect }
    var didDisconnect: AnyPublisher<Device, Never> { device.didDisconnect }
    var onValue: AnyPublisher<BluetoothValue, Never> { device.onValue }
    
    var state: ConnectionState { device.state }
    var type: DeviceType { device.type }
    
    func connect() throws {
        try device.connect()
    }
    
    func disconnect() {
        device.disconnect()
    }
    
    func handle(values: BluetoothValue) {
        for handler in handlers {
            guard handler.characteristic == values.characteristic else { continue }
            handler.handle(values: values.values)
            return
        }
        print("Unable to handle \(values.characteristic.id)")
    }
}
