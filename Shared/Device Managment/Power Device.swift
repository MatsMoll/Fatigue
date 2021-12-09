//
//  Power Device.swift
//  Power Device
//
//  Created by Mats Mollestad on 04/09/2021.
//

import Foundation
import Combine

struct PowerDeviceValue: Codable {
    let power: Int
    let cadence: Int?
    let balence: PowerBalance?
}

protocol PowerDevice: Device {
    var powerListner: AnyPublisher<PowerDeviceValue, Never> { get }
}

class PowerDeviceWrapper: BluetoothDeviceWrapper, PowerDevice {
    
    let device: BluetoothDevice
    var batteryLevel: Double? = nil
    
    private var listners: Set<AnyCancellable> = []
    
    let handlers: [BluetoothHandler]
    
    let powerListner: AnyPublisher<PowerDeviceValue, Never>
    let batteryListner: AnyPublisher<Double, Never>
    
    init(
        device: BluetoothDevice,
        powerHandler: PowerMeterHandler = BluetoothPowerHandler(),
        batteryLevelHandler: BatteryLevelHandler = BluetoothBatteryLevelHandler()
    ) {
        self.device = device
        self.handlers = [powerHandler, batteryLevelHandler]
        self.powerListner = powerHandler.powerListner
        self.batteryListner = batteryLevelHandler.batteryLevelChanged
        device.onValue.sink(receiveValue: handle(values:)).store(in: &listners)
        batteryLevelHandler.batteryLevelChanged
            .sink(receiveValue: { [weak self] newLevel in self?.batteryLevel = newLevel })
            .store(in: &listners)
    }
}
