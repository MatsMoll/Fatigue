//
//  Device Type.swift
//  Device Type
//
//  Created by Mats Mollestad on 04/09/2021.
//

import Foundation
import CoreBluetooth
import Combine

protocol DeviceType {
    var id: String { get }
    var name: String { get }
    var symbol: SFSymbol { get }
    
    func discoverer() -> DeviceDiscoverer
}

struct IdentifiableDeviceType: DeviceType, Identifiable {
    let type: DeviceType
    
    var id: String { type.id }
    var name: String { type.name }
    var symbol: SFSymbol { type.symbol }
    
    func discoverer() -> DeviceDiscoverer {
        type.discoverer()
    }
}

struct BluetoothDeviceType: DeviceType, Identifiable, Hashable {
    static func == (lhs: BluetoothDeviceType, rhs: BluetoothDeviceType) -> Bool {
        lhs.uuid == rhs.uuid
    }
    
    var id: String { uuid.uuidString }
    let uuid: CBUUID
    let symbol: SFSymbol
    let name: String
    let supportedCharacteristics: Set<BluetoothCharacteristics>
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(uuid)
    }
    
    func discoverer() -> DeviceDiscoverer {
        CoreBluetoothDeviceDiscoverer(searchingFor: self)
    }
}

extension DeviceType {
    static var powerMeter: BluetoothDeviceType {
        BluetoothDeviceType(
            uuid: CBUUID(string: "1818"),
            symbol: .boltFill,
            name: "Power",
            supportedCharacteristics: [.cyclingPowerMeasurement, .batteryLevel]
        )
    }
    
    static var heartRate: BluetoothDeviceType {
        BluetoothDeviceType(
            uuid: CBUUID(string: "180D"),
            symbol: .heartFill,
            name: "Heart Rate",
            supportedCharacteristics: [.heartRateMeasurement, .batteryLevel]
        )
    }
    
    static var powerMeterMock: DeviceTypeMock {
        .init(id: "1818", name: "Power Meter", symbol: .boltFill)
    }
}

struct DeviceTypeMock: DeviceType {
    let id: String
    let name: String
    let symbol: SFSymbol
    
    func discoverer() -> DeviceDiscoverer {
        let discoverableDevices: [BluetoothDevice] = [
            BluetoothDeviceMock(
                id: .init(),
                name: "Mats's Power Meter",
                type: .powerMeter,
                state: .disconnected,
                onValueCharecteristic: .cyclingPowerMeasurement
            ),
            BluetoothDeviceMock(
                id: .init(),
                name: "Frode's Power Meter",
                type: .powerMeter,
                state: .disconnected,
                onValueCharecteristic: .cyclingPowerMeasurement
            )
        ]
        return DeviceDiscovererMock(
            devices: discoverableDevices
        )
    }
}
