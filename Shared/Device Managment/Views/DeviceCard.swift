//
//  DeviceCard.swift
//  DeviceCard
//
//  Created by Mats Mollestad on 04/09/2021.
//

import SwiftUI

struct DeviceCard: View {
    
    let device: Device?
    
    let type: DeviceType
    
    @Binding
    var deviceDiscoverer: IdentifiableDeviceDiscoverer?
    
    var body: some View {
        VStack(spacing: 8) {
            if let device = device {
                Label(type.name, symbol: type.symbol)
                    .foregroundColor(.secondary)
                
                Text(device.name)
                    .font(.body.bold())
                
                if let batteryLevel = device.batteryLevel {
                    Text("\(Int(batteryLevel * 100))% Battery")
                }
                
                Button("Disconnect", action: disconnectFromDevice)
                    .frame(maxWidth: .infinity)
                    .foregroundColor(.red)
            } else {
                Label(type.name, symbol: type.symbol)
                
                Text("No device connected")
                    .foregroundColor(.secondary)
                
                Button("Connect Device", action: connectToDevice)
                    .frame(maxWidth: .infinity)
                    .roundedButton(color: .primary)
                    .foregroundColor(.background)
            }
        }
    }
    
    func connectToDevice() {
        deviceDiscoverer = IdentifiableDeviceDiscoverer(discoverer: type.discoverer())
    }
    
    func disconnectFromDevice() {
        device?.disconnect()
    }
}

struct DeviceCard_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            DeviceCard(
                device: nil,
                type: BluetoothDeviceType.heartRate,
                deviceDiscoverer: .constant(nil)
            )
                .preferredColorScheme(.light)
            DeviceCard(
                device: nil,
                type: BluetoothDeviceType.heartRate,
                deviceDiscoverer: .constant(nil)
            )
                .preferredColorScheme(.dark)
            DeviceCard(
                device: BluetoothDeviceMock(
                    id: .init(),
                    name: "Mats's Power Meter",
                    type: .powerMeter,
                    state: .connected,
                    onValueCharecteristic: .cyclingPowerMeasurement
                ),
                type: BluetoothDeviceType.powerMeter,
                deviceDiscoverer: .constant(nil)
            )
                .preferredColorScheme(.light)
            DeviceCard(
                device: BluetoothDeviceMock(
                    id: .init(),
                    name: "Mats's Power Meter",
                    type: .powerMeter,
                    state: .connected,
                    onValueCharecteristic: .cyclingPowerMeasurement
                ),
                type: BluetoothDeviceType.powerMeter,
                deviceDiscoverer: .constant(nil)
            )
                .preferredColorScheme(.dark)
        }
    }
}
