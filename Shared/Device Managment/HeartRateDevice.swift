//
//  HeartRateDevice.swift
//  HeartRateDevice
//
//  Created by Mats Mollestad on 04/09/2021.
//

import Foundation
import Combine

protocol HeartRateDevice: BluetoothDevice {
    var heartRateListner: AnyPublisher<HeartRateDeviceValue, Never> { get }
}

class HeartRateDeviceWrapper: BluetoothDeviceWrapper, HeartRateDevice {
    
    let device: BluetoothDevice
    var batteryLevel: Double? = nil
    
    private var listners: Set<AnyCancellable> = []
    
    var handlers: [BluetoothHandler]
    
    let heartRateListner: AnyPublisher<HeartRateDeviceValue, Never>
    let batteryListner: AnyPublisher<Double, Never>
    
    init(
        device: BluetoothDevice,
        heartRateHandler: HeartRateHandler = BluetoothHeartRateHandler(),
        batteryLevelHandler: BatteryLevelHandler = BluetoothBatteryLevelHandler()
    ) {
        self.device = device
        self.handlers = [heartRateHandler, batteryLevelHandler]
        self.heartRateListner = heartRateHandler.heartRateListner
        self.batteryListner = batteryLevelHandler.batteryLevelChanged
        device.onValue.sink(receiveValue: handle(values:)).store(in: &listners)
        batteryLevelHandler.batteryLevelChanged
            .sink(receiveValue: { [weak self] newLevel in self?.batteryLevel = newLevel })
            .store(in: &listners)
    }
}
