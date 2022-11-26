//
//  BluetoothDeviceMock.swift
//  BluetoothDeviceMock
//
//  Created by Mats Mollestad on 04/09/2021.
//

import Foundation
import Combine

/// Mocking a bluetooth device for testing purpuses
class BluetoothDeviceMock: BluetoothDevice, Hashable {
    
    let id: UUID
    let name: String
    let type: DeviceType
    var state: ConnectionState
    let batteryLevel: Double? = 0.8
    let onValueCharecteristic: BluetoothCharacteristics
    
    internal init(id: UUID, name: String, type: BluetoothDeviceType, state: ConnectionState, onValueCharecteristic: BluetoothCharacteristics) {
        self.id = id
        self.name = name
        self.type = type
        self.state = state
        self.onValueCharecteristic = onValueCharecteristic
    }
    
    var didConnect: AnyPublisher<Device, Never> { didConnectSubject.eraseToAnyPublisher() }
    var didDisconnect: AnyPublisher<Device, Never> { didDisconnectSubject.eraseToAnyPublisher() }
    
    var unableToConnect: AnyPublisher<Device, Never> { PassthroughSubject().eraseToAnyPublisher() }
    
    var batteryListner: AnyPublisher<Double, Never> { Just(0.8).eraseToAnyPublisher() }
    
    var onValue: AnyPublisher<BluetoothValue, Never> {
        let value = BluetoothValue(
            characteristic: onValueCharecteristic,
            values: [0, 0, 0, 0]
        )
        return onValueTimer.map { _ in value }
            .eraseToAnyPublisher()
    }
    
    private let didConnectSubject = PassthroughSubject<Device, Never>()
    private let didDisconnectSubject = PassthroughSubject<Device, Never>()
    private let onValueTimer = Timer.publish(every: 1, on: .current, in: .default)
    private var timer: Cancellable?
    
    func connect() throws {
        state = .connected
        didConnectSubject.send(self)
        timer = onValueTimer.connect()
    }
    func disconnect() {
        state = .disconnected
        didDisconnectSubject.send(self)
        timer?.cancel()
    }
    
    
    static func == (lhs: BluetoothDeviceMock, rhs: BluetoothDeviceMock) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
