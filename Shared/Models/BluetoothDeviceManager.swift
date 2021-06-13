//
//  BluetoothDeviceManager.swift
//  Fatigue
//
//  Created by Mats Mollestad on 10/06/2021.
//

import Foundation
import CoreBluetooth
import Combine

struct BluetoothDeviceType: Identifiable, Hashable {
    static func == (lhs: BluetoothDeviceType, rhs: BluetoothDeviceType) -> Bool {
        lhs.uuid == rhs.uuid
    }
    
    var id: String { uuid.uuidString }
    let uuid: CBUUID
    let systemImage: String
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(uuid)
    }
    
    static let heartRate = BluetoothDeviceType(
        uuid: CBUUID(string: "180D"),
        systemImage: "heart.fill"
    )
    
    static let powerMeter = BluetoothDeviceType(
        uuid: CBUUID(string: "1818"),
        systemImage: "bolt.fill"
    )
}

struct BluetoothDevice: Identifiable, Hashable {
    
    var id: UUID { peripheral.identifier }
    var name: String { peripheral.name ?? "Missing name" }
    let type: BluetoothDeviceType
    var state: CBPeripheralState { peripheral.state }
    
    let peripheral: CBPeripheral
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    internal init(peripheral: CBPeripheral, type: BluetoothDeviceType) {
        self.peripheral = peripheral
        self.type = type
    }
}

struct BluetoothManagerError: Error {
    
    let reason: String
    
    internal init(reason: String) {
        self.reason = reason
    }
}

class BluetoothConnector: NSObject, ObservableObject {
    
    let central: CBCentralManager
    
    let type: BluetoothDeviceType
    
    let handler: BluetoothHandler
    
    @Published
    var managerState: CBManagerState = .unknown
    
    @Published
    var devices: Set<BluetoothDevice> = []
    
    @Published
    var focusedDevice: BluetoothDevice?
    
    
    init(central: CBCentralManager, type: BluetoothDeviceType, handler: BluetoothHandler) {
        self.central = central
        self.type = type
        self.handler = handler
        super.init()
        central.delegate = self
    }
    
    func startScanning() throws {
        guard case CBManagerState.poweredOn = central.state else {
            throw BluetoothManagerError(reason: "BluetoothManager is not powered on")
        }
        central.scanForPeripherals(withServices: [type.uuid])
    }
    
    func connect(to device: BluetoothDevice) {
        guard focusedDevice == nil else { return }
        device.peripheral.delegate = self
        central.connect(device.peripheral, options: nil)
        focusedDevice = device
    }
}

extension BluetoothConnector: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        DispatchQueue.main.async { [weak self] in
            self?.managerState = central.state
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        let device = BluetoothDevice(peripheral: peripheral, type: type)
        if !devices.contains(device) {
            DispatchQueue.main.async { [weak self] in
                self?.devices.insert(device)
            }
        }
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        // Connected to periphial
        let strongType = type
        DispatchQueue.main.async { [weak self] in
            self?.focusedDevice = BluetoothDevice(peripheral: peripheral, type: strongType)
        }
        peripheral.discoverServices(nil)
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        // Disconnected
    }
}

extension BluetoothConnector: CBPeripheralDelegate {
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let services = peripheral.services else { return }
        for service in services {
            peripheral.discoverCharacteristics(nil, for: service)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard let characteristics = service.characteristics else { return }
        let uuid = CBUUID(string: handler.characteristicID)
        for char in characteristics {
            guard char.uuid == uuid else {
                return
            }
            if char.properties.contains(.read) {
                peripheral.readValue(for: char)
            } else if char.properties.contains(.notify) {
                peripheral.setNotifyValue(true, for: char)
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        guard let data = characteristic.value else { return }
        let values = [UInt8].init(data)
        handler.handle(values: values)
    }
}


class BluetoothManager {
    
    var connectors = [BluetoothDeviceType: BluetoothConnector]()
    var handlers = [BluetoothDeviceType: BluetoothHandler]()
    
    let queue: DispatchQueue
    
    init(queue: DispatchQueue = DispatchQueue.global(qos: .background)) {
        self.queue = queue
    }
    
    func register(handler: BluetoothHandler, for type: BluetoothDeviceType) {
        handlers[type] = handler
    }
    
    func hasConnected(to type: BluetoothDeviceType) -> Bool {
        connectors[type]?.focusedDevice?.state == .connected
    }
    
    func connector(for type: BluetoothDeviceType) throws -> BluetoothConnector {
        if let connector = connectors[type] { return connector }
        
        guard let handler = handlers[type] else {
            throw BluetoothManagerError(reason: "Missing handler for \(type)")
        }
        
        let newConnector = BluetoothConnector(
            central: .init(delegate: nil, queue: queue),
            type: type,
            handler: handler
        )
        connectors[type] = newConnector
        return newConnector
    }
}
