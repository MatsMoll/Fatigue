//
//  Bluetooth Device.swift
//  Bluetooth Device
//
//  Created by Mats Mollestad on 04/09/2021.
//

import Foundation
import Combine
#if os(iOS)
import CoreBluetooth
#endif

enum ConnectionState {
    case connecting
    case disconnecting
    case connected
    case disconnected
}

#if os(iOS)
extension ConnectionState {
    init?(state: CBPeripheralState) {
        switch state {
        case .connected: self = .connected
        case .connecting: self = .connecting
        case .disconnecting: self = .disconnecting
        case .disconnected: self = .disconnected
        default: return nil
        }
    }
}
#endif

protocol Device {
    var id: UUID { get }
    var name: String { get }
    var type: DeviceType { get }
    var state: ConnectionState { get }
    var batteryLevel: Double? { get }
    
    var didConnect: AnyPublisher<Device, Never> { get }
    var didDisconnect: AnyPublisher<Device, Never> { get }
    var unableToConnect: AnyPublisher<Device, Never> { get }
    
    func connect() throws
    func disconnect()
}


protocol BluetoothDevice: Device {
    var id: UUID { get }
    var name: String { get }
    var type: DeviceType { get }
    var state: ConnectionState { get }
    var batteryLevel: Double? { get }
    
    var didConnect: AnyPublisher<Device, Never> { get }
    var didDisconnect: AnyPublisher<Device, Never> { get }
    var unableToConnect: AnyPublisher<Device, Never> { get }
    
    var onValue: AnyPublisher<BluetoothValue, Never> { get }
    
    func connect() throws
    func disconnect()
}
