//
//  ConnectionListner.swift
//  ConnectionListner
//
//  Created by Mats Mollestad on 04/09/2021.
//

import Combine

class ConnectionListner: ObservableObject {
    
    var listners: Set<AnyCancellable> = []
    
    @Published
    var connectionState: ConnectionState = .connecting
    
    let deviceManager: DeviceManager
    
    var powerHandler: PowerMeterHandler {
        #if DEBUG
        BluetoothPowerHandlerMock()
        #else
        BluetoothPowerHandler()
        #endif
    }
    
    var heartRateHandler: HeartRateHandler {
        BluetoothHeartRateHandler()
    }
    
    init(deviceManager: DeviceManager) {
        self.deviceManager = deviceManager
    }
    
    func listen(to device: Device, didConnect: @escaping (Device) -> Void) {
        listners = []
        device.didConnect.sink(receiveValue: store(_:)).store(in: &listners)
        device.didConnect.sink(receiveValue: didConnect).store(in: &listners)
        device.didDisconnect.sink { [weak self] _ in
            self?.connectionState = .disconnected
        }
        .store(in: &listners)
    }
    
    func store(_ device: Device) {
        connectionState = .connected
        switch device.type.id {
        case BluetoothDeviceType.powerMeter.id:
            guard let bluetoothDevice = device as? BluetoothDevice else { return }
            deviceManager.powerDevice = PowerDeviceWrapper(
                device: bluetoothDevice,
                powerHandler: powerHandler
            )
        case BluetoothDeviceType.heartRate.id:
            guard let bluetoothDevice = device as? BluetoothDevice else { return }
            deviceManager.heartRateDevice = HeartRateDeviceWrapper(
                device: bluetoothDevice,
                heartRateHandler: heartRateHandler
            )
        default:
            print("Not storing device of type: \(device.type)")
        }
    }
}
