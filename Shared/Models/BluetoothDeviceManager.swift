////
////  BluetoothDeviceManager.swift
////  Fatigue
////
////  Created by Mats Mollestad on 10/06/2021.
////
//
//import Foundation
//import CoreBluetooth
//import Combine
//
//struct BluetoothDeviceType: Identifiable, Hashable {
//    static func == (lhs: BluetoothDeviceType, rhs: BluetoothDeviceType) -> Bool {
//        lhs.uuid == rhs.uuid
//    }
//
//    var id: String { uuid.uuidString }
//    let uuid: CBUUID
//    let systemImage: String
//
//    func hash(into hasher: inout Hasher) {
//        hasher.combine(uuid)
//    }
//
//    static let heartRate = BluetoothDeviceType(
//        uuid: CBUUID(string: "180D"),
//        systemImage: "heart.fill"
//    )
//
//    static let powerMeter = BluetoothDeviceType(
//        uuid: CBUUID(string: "1818"),
//        systemImage: "bolt.fill"
//    )
//}
//
////struct BluetoothDevice: Identifiable, Hashable {
////
////    var id: UUID { peripheral.identifier }
////    var name: String { peripheral.name ?? "Missing name" }
////    let type: BluetoothDeviceType
////    var state: CBPeripheralState { peripheral.state }
////
////    let peripheral: CBPeripheral
////
////    func hash(into hasher: inout Hasher) {
////        hasher.combine(id)
////    }
////
////    internal init(peripheral: CBPeripheral, type: BluetoothDeviceType) {
////        self.peripheral = peripheral
////        self.type = type
////    }
////}
//
//struct BluetoothManagerError: Error {
//
//    let reason: String
//
//    internal init(reason: String) {
//        self.reason = reason
//    }
//}
//
//enum BluetoothSensorState: Int, Equatable {
//    case unknown
//    case resetting
//    case unsupported
//    case unauthorized
//    case poweredOff
//    case poweredOn
//}
//
//enum BluetoothDeviceState: Int, Equatable {
//    case disconnected = 0
//    case connecting = 1
//    case connected = 2
//    case disconnecting = 3
//}
//
//protocol BluetoothDeviceDiscoverer {
//
//    var devices: [ConnectableBluetoothDevice] { get }
//    var sensorState: BluetoothSensorState { get }
//
//    var sensorStateChanged: AnyPublisher<BluetoothSensorState, Never> { get }
//
//    var onUpdatedValues: AnyPublisher<[ConnectableBluetoothDevice], Never> { get }
//    var onDisconnect: AnyPublisher<UUID, Never> { get }
//
//    func search(for type: BluetoothDeviceType) throws
//
//    func stopSearch()
//}
//
////protocol BluetoothDeviceDiscovererDelegate: AnyObject {
////    func sensor(changed state: BluetoothSensorState)
////    func discovered(device: ConnectableBluetoothDevice)
////
////    func disconnected(from device: BluetoothDevice)
////    func connected(to device: BluetoothDevice)
////}
//
//protocol ConnectableBluetoothDevice {
//    var id: UUID { get }
//    var name: String { get }
//    var type: BluetoothDeviceType { get }
//    var state: CBPeripheralState { get }
//
//    var connectionSucceeded: AnyPublisher<ConnectableBluetoothDevice, Never> { get }
//    var unableToConnect: AnyPublisher<ConnectableBluetoothDevice, Never> { get }
//
//    func connect(with handler: BluetoothHandler)
//    func disconnect()
//}
//
//// Discover devices (Code)
//// Select device (User input)
//// connect to device, services, and chars (Code)
//
//struct CoreBluetoothBluetoothDevice: ConnectableBluetoothDevice, Identifiable, Hashable {
//
//    static func == (lhs: CoreBluetoothBluetoothDevice, rhs: CoreBluetoothBluetoothDevice) -> Bool {
//        lhs.id == rhs.id
//    }
//
//    var id: UUID { peripheral.identifier }
//    var name: String { peripheral.name ?? "Missing name" }
//    let type: BluetoothDeviceType
//    var state: CBPeripheralState { peripheral.state }
//
//    var connectionSucceeded: AnyPublisher<ConnectableBluetoothDevice, Never> {
//        discoverer.connectionSucceeded
//            .filter({ $0 == self.id })
//            .map { _ in self }
//            .eraseToAnyPublisher()
//    }
//
//    var unableToConnect: AnyPublisher<ConnectableBluetoothDevice, Never> {
//        discoverer.unableToConnect
//            .filter({ $0 == self.id })
//            .map { _ in self }
//            .eraseToAnyPublisher()
//    }
//
//    let peripheral: CBPeripheral
//    var central: CBCentralManager { discoverer.central }
//
//    let connector: CoreBluetoothDeviceConnector
//    let discoverer: CoreBluetoothDeviceDiscoverer
//
//    func hash(into hasher: inout Hasher) {
//        hasher.combine(id)
//    }
//
//    internal init(peripheral: CBPeripheral, type: BluetoothDeviceType, discoverer: CoreBluetoothDeviceDiscoverer) {
//        self.peripheral = peripheral
//        self.type = type
//        self.discoverer = discoverer
//        self.connector = .init()
//    }
//
//    func connect(with handler: BluetoothHandler) {
//        connector.handler = handler
//        peripheral.delegate = connector
//        central.stopScan()
//        central.connect(peripheral, options: nil)
//    }
//
//    func disconnect() {
//        central.cancelPeripheralConnection(peripheral)
//    }
//}
//
//class CoreBluetoothDeviceConnector: NSObject {
//    var handler: BluetoothHandler?
//
//    init(handler: BluetoothHandler? = nil) {
//        self.handler = handler
//        super.init()
//    }
//}
//
//extension CoreBluetoothDeviceConnector: CBPeripheralDelegate {
//
//    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
//        guard let services = peripheral.services else { return }
//        for service in services {
//            peripheral.discoverCharacteristics(nil, for: service)
//        }
//    }
//
//    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
//        guard
//            let characteristics = service.characteristics,
//            let handlerChar = handler?.characteristicID
//        else { return }
//
//        let uuid = CBUUID(string: handlerChar)
//        for char in characteristics {
//            guard char.uuid == uuid else { continue }
//            if char.properties.contains(.read) {
//                peripheral.readValue(for: char)
//            } else if char.properties.contains(.notify) {
//                peripheral.setNotifyValue(true, for: char)
//            }
//        }
//    }
//
//    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
//        guard let data = characteristic.value else { return }
//        let values = [UInt8].init(data)
//        handler?.handle(values: values)
//    }
//}
//
////class CoreBluetoothDeviceDiscoverer: NSObject, BluetoothDeviceDiscoverer {
////
////    @Published
////    var devices: [ConnectableBluetoothDevice] = []
////
////    private(set) var discoveredDevices: Set<CoreBluetoothBluetoothDevice> = []
////
////    @Published
////    var sensorState: BluetoothSensorState = .unknown
////
////    var connectionSucceeded: AnyPublisher<UUID, Never> { connectionSucceededSubject.eraseToAnyPublisher() }
////    private var connectionSucceededSubject = PassthroughSubject<UUID, Never>()
////
////    var unableToConnect: AnyPublisher<UUID, Never> { unableToConnectSubject.eraseToAnyPublisher() }
////    private var unableToConnectSubject = PassthroughSubject<UUID, Never>()
////
////    var onUpdatedValues: AnyPublisher<[ConnectableBluetoothDevice], Never> { $devices.eraseToAnyPublisher() }
////
////    var onDisconnect: AnyPublisher<UUID, Never> { onDisconnectSubject.eraseToAnyPublisher() }
////    var onDisconnectSubject = PassthroughSubject<UUID, Never>()
////
////    var sensorStateChanged: AnyPublisher<BluetoothSensorState, Never> { $sensorState.eraseToAnyPublisher() }
////
////    var searchingType: BluetoothDeviceType?
////    let central: CBCentralManager
////
////    init(central: CBCentralManager = .init()) {
////        self.central = central
////        sensorState = BluetoothSensorState(rawValue: central.state.rawValue) ?? .unknown
////        super.init()
////        central.delegate = self
////    }
////
////    func search(for type: BluetoothDeviceType) throws {
////        stopSearch()
////        guard central.state == .poweredOn else {
////            throw BluetoothManagerError(reason: "Bluetooth is not powered on")
////        }
////        searchingType = type
////        central.scanForPeripherals(withServices: [type.uuid], options: nil)
////    }
////
////    func stopSearch() {
////        central.stopScan()
////        discoveredDevices = []
////    }
////}
////
////extension CoreBluetoothDeviceDiscoverer: CBCentralManagerDelegate {
////
////    func centralManagerDidUpdateState(_ central: CBCentralManager) {
////        DispatchQueue.main.async { [weak self] in
////            self?.sensorState = BluetoothSensorState(rawValue: central.state.rawValue) ?? .unknown
////        }
////    }
////
////    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
////        guard let searchingType = searchingType else { return }
////        let device = CoreBluetoothBluetoothDevice(peripheral: peripheral, type: searchingType, discoverer: self)
////        if !discoveredDevices.contains(device) {
////            discoveredDevices.insert(device)
////            let newDevices = Array(discoveredDevices)
////            DispatchQueue.main.async { [weak self] in
////                self?.devices = newDevices
////            }
////        }
////    }
////
////    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
////        // Connected to periphial
////        peripheral.discoverServices(nil)
////        let newDevices = Array(discoveredDevices)
////        // Refreshing the state of the devices
////        DispatchQueue.main.async { [weak self] in
////            self?.devices = newDevices
////        }
////        connectionSucceededSubject.send(peripheral.identifier)
////    }
////
////    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
////        // Disconnected
////        onDisconnectSubject.send(peripheral.identifier)
////    }
////
////    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
////        unableToConnectSubject.send(peripheral.identifier)
////    }
////}
////
////class BluetoothManager: ObservableObject {
////
////    private var sensorStateUpdatedListner: AnyCancellable?
////
////    var state: BluetoothSensorState { deviceDiscoverer.sensorState }
////
////    var connectedDevices: [UUID: ConnectableBluetoothDevice]
////    var reconnectTo: [UUID: ConnectableBluetoothDevice] {
////        didSet {
////
//////            if reconnectTo.isEmpty {
//////                reconnectTimer?.invalidate()
//////                reconnectTimer = nil
//////                print("Invalidationg timer")
//////            } else if reconnectTimer == nil {
//////                reconnectTimer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true, block: { _ in
//////                    print("Running block")
//////                    self.reconnect()
//////                })
//////                reconnectTimer?.fire()
//////                print("Setting timer")
//////            }
////        }
////    }
////
////    private var reconnectTimer: Timer?
////
////    var handlers: [BluetoothDeviceType : BluetoothHandler]
////
////    lazy var deviceDiscoverer: BluetoothDeviceDiscoverer = CoreBluetoothDeviceDiscoverer(central: .init(delegate: nil, queue: .global()))
////
////    private var onDisconnectListner: AnyCancellable?
////
////    private var connectionListners: Set<AnyCancellable> = []
////
////    init(handlers: [BluetoothDeviceType : BluetoothHandler] = [:]) {
////        self.handlers = handlers
////        self.reconnectTo = [:]
////        self.connectedDevices = [:]
////        self.reconnectTimer = Timer.scheduledTimer(withTimeInterval: 15, repeats: true, block: { [weak self] _ in
////            self?.reconnect()
////        })
////    }
////
////    func has(connected type: BluetoothDeviceType) -> Bool {
////        connectedDevices.values.contains(where: { $0.type == type && $0.state == .connected })
////    }
////
////    func register(handler: BluetoothHandler, for type: BluetoothDeviceType) {
////        handlers[type] = handler
////    }
////
////    func discoverDevices(_ type: BluetoothDeviceType) throws {
////        if onDisconnectListner == nil {
////            onDisconnectListner = deviceDiscoverer.onDisconnect
////                .sink(receiveValue: { [weak self] deviceUUID in
////                    guard let device = self?.connectedDevices[deviceUUID] else { return }
////                    self?.reconnectTo[device.id] = device
////            })
////        }
////        try deviceDiscoverer.search(for: type)
////    }
////
////    func connect(to device: ConnectableBluetoothDevice) throws {
////        guard let handler = handlers[device.type] else {
////            throw GenericError(reason: "Missing handler for bluetooth device")
////        }
////        device.connect(with: handler)
////        // Fire UI update
////        objectWillChange.send()
////        device.connectionSucceeded
////            .receive(on: DispatchQueue.main)
////            .sink { [weak self] device in
////                self?.connectedDevices[device.id] = device
////                self?.reconnectTo[device.id] = nil
////                self?.objectWillChange.send()
////        }
////        .store(in: &connectionListners)
////
////        device.unableToConnect.sink(receiveValue: { device in
////            print("Unable to connect to device: \(device.id)")
////        })
////        .store(in: &connectionListners)
////    }
////
////    func reconnect() {
////        for device in reconnectTo.values {
////            do {
////                try connect(to: device)
////            } catch {
////                print("Reconnect error: \(error)")
////            }
////        }
////    }
////}
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
////class BluetoothConnector: NSObject, ObservableObject {
////
////    let central: CBCentralManager
////
////    let type: BluetoothDeviceType
////
////    let handler: BluetoothHandler
////
////    @Published
////    var managerState: CBManagerState = .unknown
////
////    @Published
////    var devices: Set<BluetoothDevice> = []
////
////    @Published
////    var focusedDevice: BluetoothDevice?
////
////
////    init(central: CBCentralManager, type: BluetoothDeviceType, handler: BluetoothHandler) {
////        self.central = central
////        self.type = type
////        self.handler = handler
////        super.init()
////        central.delegate = self
////    }
////
////    func startScanning() throws {
////        guard central.state == .poweredOn else {
////            throw BluetoothManagerError(reason: "Bluetooth is not powered on")
////        }
////        central.scanForPeripherals(withServices: [type.uuid])
////    }
////
////    func connect(to device: BluetoothDevice) {
////        guard focusedDevice == nil else { return }
////        device.peripheral.delegate = self
////        central.connect(device.peripheral, options: nil)
////        focusedDevice = device
////    }
////}
////
////extension BluetoothConnector: CBCentralManagerDelegate {
////    func centralManagerDidUpdateState(_ central: CBCentralManager) {
////        DispatchQueue.main.async { [weak self] in
////            self?.managerState = central.state
////        }
////    }
////
////    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
////        let device = BluetoothDevice(peripheral: peripheral, type: type)
////        if !devices.contains(device) {
////            DispatchQueue.main.async { [weak self] in
////                self?.devices.insert(device)
////            }
////        }
////    }
////
////    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
////        // Connected to periphial
////        let strongType = type
////        DispatchQueue.main.async { [weak self] in
////            self?.focusedDevice = BluetoothDevice(peripheral: peripheral, type: strongType)
////        }
////        peripheral.discoverServices(nil)
////    }
////
////    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
////        // Disconnected
////    }
////}
////
////extension BluetoothConnector: CBPeripheralDelegate {
////
////    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
////        guard let services = peripheral.services else { return }
////        for service in services {
////            peripheral.discoverCharacteristics(nil, for: service)
////        }
////    }
////
////    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
////        guard let characteristics = service.characteristics else { return }
////        let uuid = CBUUID(string: handler.characteristicID)
////        for char in characteristics {
////            guard char.uuid == uuid else {
////                return
////            }
////            if char.properties.contains(.read) {
////                peripheral.readValue(for: char)
////            } else if char.properties.contains(.notify) {
////                peripheral.setNotifyValue(true, for: char)
////            }
////        }
////    }
////
////    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
////        guard let data = characteristic.value else { return }
////        let values = [UInt8].init(data)
////        handler.handle(values: values)
////    }
////}
////
//
////class BluetoothManager: ObservableObject {
////
////    var connectors = [BluetoothDeviceType: BluetoothConnector]()
////    var handlers = [BluetoothDeviceType: BluetoothHandler]()
////
////    let queue: DispatchQueue
////
////    init(queue: DispatchQueue = DispatchQueue.global(qos: .background)) {
////        self.queue = queue
////    }
////
////    func register(handler: BluetoothHandler, for type: BluetoothDeviceType) {
////        handlers[type] = handler
////    }
////
////    func hasConnected(to type: BluetoothDeviceType) -> Bool {
////        connectors[type]?.focusedDevice?.state == .connected
////    }
////
////    func connector(for type: BluetoothDeviceType) throws -> BluetoothConnector {
////        if let connector = connectors[type] { return connector }
////
////        guard let handler = handlers[type] else {
////            throw BluetoothManagerError(reason: "Missing handler for \(type)")
////        }
////
////        let newConnector = BluetoothConnector(
////            central: .init(delegate: nil, queue: queue),
////            type: type,
////            handler: handler
////        )
////        connectors[type] = newConnector
////        return newConnector
////    }
////}
