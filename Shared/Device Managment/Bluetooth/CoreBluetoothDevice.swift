//
//  CoreBluetoothDevice.swift
//  CoreBluetoothDevice
//
//  Created by Mats Mollestad on 04/09/2021.
//

import Foundation
import Combine
import CoreBluetooth

/// A Real bluetooth device
class CoreBluetoothDevice: BluetoothDevice, Hashable {
    static func == (lhs: CoreBluetoothDevice, rhs: CoreBluetoothDevice) -> Bool {
        lhs.id == rhs.id
    }
    
    var id: UUID { peripheral.identifier }
    var name: String { peripheral.name ?? "Missing name" }
    let type: DeviceType
    var state: ConnectionState { ConnectionState(state: peripheral.state) ?? .disconnected }
    var batteryLevel: Double? = nil
    
    var didConnect: AnyPublisher<Device, Never> {
        let id = self.id
        return discoverer.didConnect
            .filter({ $0 == id })
            .compactMap { [weak self] _ in
                self?.reconnectTimer?.invalidate()
                self?.reconnectTimer = nil
                return self
            }
            .eraseToAnyPublisher()
    }
    
    var unableToConnect: AnyPublisher<Device, Never> {
        let id = self.id
        return discoverer.unableToConnect
            .filter({ $0 == id })
            .compactMap { [weak self] _ in self }
            .eraseToAnyPublisher()
    }
    
    private let didDisconnectSubject = PassthroughSubject<Device, Never>()
    
    var didDisconnect: AnyPublisher<Device, Never> { didDisconnectSubject.eraseToAnyPublisher() }
    var onValue: AnyPublisher<BluetoothValue, Never> { connector.valuePublisher }
    
    private var disconnectedListner: AnyCancellable?
    
    let peripheral: CBPeripheral
    var central: CBCentralManager { discoverer.central }
    private let connector: CoreBluetoothDeviceConnector
    let discoverer: CoreBluetoothDeviceDiscoverer
    private var reconnectTimer: Timer?
    
    
    internal init(
        peripheral: CBPeripheral,
        type: BluetoothDeviceType,
        discoverer: CoreBluetoothDeviceDiscoverer
    ) {
        self.peripheral = peripheral
        self.type = type
        self.discoverer = discoverer
        self.connector = CoreBluetoothDeviceConnector(supportedCharacteristics: type.supportedCharacteristics)
        let id = peripheral.identifier
        self.disconnectedListner = discoverer.didDisconnect
            .filter({ $0 == id })
            .sink(receiveValue: { [weak self] _ in self?.setupReconnectTimer() })
    }
    
    func connect() throws {
        peripheral.delegate = connector
        central.connect(peripheral, options: nil)
        central.stopScan()
    }
    
    func disconnect() {
        disconnectedListner?.cancel()
        central.cancelPeripheralConnection(peripheral)
        didDisconnectSubject.send(self)
    }
    
    
    func setupReconnectTimer() {
        reconnectTimer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true, block: { [weak self] _ in
            try? self?.connect()
        })
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
