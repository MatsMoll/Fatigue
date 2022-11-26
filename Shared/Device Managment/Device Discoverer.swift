//
//  DeviceDiscoverer.swift
//  DeviceDiscoverer
//
//  Created by Mats Mollestad on 04/09/2021.
//

import Foundation
#if os(iOS)
import CoreBluetooth
#endif
import Combine

enum DeviceDiscovererState: Int {
    case unknown = 0
    case resetting = 1
    case unsupported = 2
    case unauthorized = 3
    case poweredOff = 4
    case poweredOn = 5
    
    #if os(iOS)
    init?(state: CBManagerState) {
        self.init(rawValue: state.rawValue)
    }
    #endif
    
    var description: String {
        switch self {
        case .unknown: return "Unknown state"
        case .resetting: return "Resetting"
        case .unsupported: return "Unsupported"
        case .unauthorized: return "Unauthorized"
        case .poweredOn: return "Powered On"
        case .poweredOff: return "Powered Off"
        }
    }
}

/// A protocol defining a way of fetching and listing connectable devices
protocol DeviceDiscoverer {
    
    var devices: [BluetoothDevice] { get }
    var state: DeviceDiscovererState { get }
    
    var onUpdatedValues: AnyPublisher<[BluetoothDevice], Never> { get }
    var onUpdatedState: AnyPublisher<DeviceDiscovererState, Never> { get }
    
    func startSearch() throws
    func stopSearch()
}

struct IdentifiableDeviceDiscoverer: Identifiable {
    let id: UUID = .init()
    let discoverer: DeviceDiscoverer
}

class DeviceDiscovererMock: DeviceDiscoverer {
    
    @Published
    var devices: [BluetoothDevice]
    
    @Published
    var state: DeviceDiscovererState = .poweredOff
    
    let loadedDevices: [BluetoothDevice]
    
    var onUpdatedValues: AnyPublisher<[BluetoothDevice], Never> { $devices.eraseToAnyPublisher() }
    var onUpdatedState: AnyPublisher<DeviceDiscovererState, Never> { $state.eraseToAnyPublisher() }
    
    init(devices: [BluetoothDevice]) {
        self.devices = []
        self.loadedDevices = devices
        Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { [weak self] _ in
            self?.state = .poweredOn
        }
    }
    
    func startSearch() throws {
        devices = loadedDevices
    }
    
    func stopSearch() {}
}

struct CoreBluetoothDeviceDiscovererError: Error, LocalizedError {
    
    let reason: String
    
    internal init(reason: String) {
        self.reason = reason
    }
    
    var errorDescription: String? { reason }
}

#if os(iOS)
class CoreBluetoothDeviceDiscoverer: NSObject, DeviceDiscoverer {
    
    private static var _sharedBluetoothCentral: CBCentralManager?
    static var sharedBluetoothCentral: CBCentralManager {
        if let central = _sharedBluetoothCentral {
            return central
        } else {
            _sharedBluetoothCentral = .init()
            return _sharedBluetoothCentral!
        }
    }
    
    @Published
    var devices: [BluetoothDevice] = []
    
    @Published
    var state: DeviceDiscovererState = .unknown
    
    private(set) var discoveredDevices: Set<CoreBluetoothDevice> = []
    
    let searchingType: BluetoothDeviceType
    let central: CBCentralManager
    
    
    var didConnect: AnyPublisher<UUID, Never> { didConnectSubject.eraseToAnyPublisher() }
    var unableToConnect: AnyPublisher<UUID, Never> { unableToConnectSubject.eraseToAnyPublisher() }
    var didDisconnect: AnyPublisher<UUID, Never> { didDisconnectedSubject.eraseToAnyPublisher() }
    var onUpdatedValues: AnyPublisher<[BluetoothDevice], Never> { $devices.eraseToAnyPublisher() }
    var onUpdatedState: AnyPublisher<DeviceDiscovererState, Never> { $state.eraseToAnyPublisher() }
    
    private var didConnectSubject = PassthroughSubject<UUID, Never>()
    private var unableToConnectSubject = PassthroughSubject<UUID, Never>()
    private let didDisconnectedSubject = PassthroughSubject<UUID, Never>()
    
    
    init(searchingFor: BluetoothDeviceType, central: CBCentralManager = CoreBluetoothDeviceDiscoverer.sharedBluetoothCentral) {
        self.central = central
        self.searchingType = searchingFor
        super.init()
        central.delegate = self
        state = .init(state: central.state) ?? .unknown
    }
    
    func startSearch() throws {
        guard central.state == .poweredOn else {
            throw CoreBluetoothDeviceDiscovererError(reason: "Bluetooth is not powered on")
        }
        central.scanForPeripherals(withServices: [searchingType.uuid], options: nil)
    }
    
    func stopSearch() {
        central.stopScan()
        discoveredDevices = []
    }
}

extension CoreBluetoothDeviceDiscoverer: CBCentralManagerDelegate {
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        DispatchQueue.main.async { [weak self] in
            self?.state = DeviceDiscovererState(state: central.state) ?? .unknown
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        let device = CoreBluetoothDevice(
            peripheral: peripheral,
            type: searchingType,
            discoverer: self
        )
        if !discoveredDevices.contains(device) {
            discoveredDevices.insert(device)
            let newDevices = Array(discoveredDevices)
            DispatchQueue.main.async { [weak self] in
                self?.devices = newDevices
            }
        }
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        didConnectSubject.send(peripheral.identifier)
        // Connected to periphial
        peripheral.discoverServices(nil)
        let newDevices = Array(discoveredDevices)
        
        // Refreshing the state of the devices
        DispatchQueue.main.async { [weak self] in
            self?.devices = newDevices
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        // Disconnected
        didDisconnectedSubject.send(peripheral.identifier)
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        unableToConnectSubject.send(peripheral.identifier)
    }
}
#else
class CoreBluetoothDeviceDiscoverer: DeviceDiscoverer {
    
    @Published
    var devices: [BluetoothDevice] = []
    
    @Published
    var state: DeviceDiscovererState = .unknown
    
    let searchingType: BluetoothDeviceType
    
    
    var didConnect: AnyPublisher<UUID, Never> { didConnectSubject.eraseToAnyPublisher() }
    var unableToConnect: AnyPublisher<UUID, Never> { unableToConnectSubject.eraseToAnyPublisher() }
    var didDisconnect: AnyPublisher<UUID, Never> { didDisconnectedSubject.eraseToAnyPublisher() }
    var onUpdatedValues: AnyPublisher<[BluetoothDevice], Never> { $devices.eraseToAnyPublisher() }
    var onUpdatedState: AnyPublisher<DeviceDiscovererState, Never> { $state.eraseToAnyPublisher() }
    
    private var didConnectSubject = PassthroughSubject<UUID, Never>()
    private var unableToConnectSubject = PassthroughSubject<UUID, Never>()
    private let didDisconnectedSubject = PassthroughSubject<UUID, Never>()
    
    
    init(searchingFor: BluetoothDeviceType) {
        self.searchingType = searchingFor
        state = .unknown
    }
    
    func startSearch() throws {
        throw CoreBluetoothDeviceDiscovererError(reason: "Bluetooth is not powered on")
    }
    
    func stopSearch() {
        
    }
}
#endif
