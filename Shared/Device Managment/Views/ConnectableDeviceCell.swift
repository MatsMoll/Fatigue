//
//  ConnectableDeviceCell.swift
//  ConnectableDeviceCell
//
//  Created by Mats Mollestad on 04/09/2021.
//

import SwiftUI

struct ConnectableDeviceCell: View {
    
    let device: BluetoothDevice
    
    var body: some View {
        HStack {
            if device.state == .connecting {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
            } else if device.state == .connected {
                Image(symbol: .checkmark)
            }
            
            Label(device.name, symbol: device.type.symbol)
                .id(device.id)
        }
    }
}

struct ConnectableDeviceCell_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ConnectableDeviceCell(
                device: BluetoothDeviceMock(
                    id: .init(),
                    name: "Mats's Power Meter",
                    type: .powerMeter,
                    state: .connected,
                    onValueCharecteristic: .cyclingPowerMeasurement
                )
            )
            .previewLayout(.sizeThatFits)
            ConnectableDeviceCell(
                device: BluetoothDeviceMock(
                    id: .init(),
                    name: "Mats's Power Meter",
                    type: .powerMeter,
                    state: .connecting,
                    onValueCharecteristic: .cyclingPowerMeasurement
                )
            )
            .previewLayout(.sizeThatFits)
            ConnectableDeviceCell(
                device: BluetoothDeviceMock(
                    id: .init(),
                    name: "Mats's Heart Rate",
                    type: .heartRate,
                    state: .disconnected,
                    onValueCharecteristic: .cyclingPowerMeasurement
                )
            )
            .previewLayout(.sizeThatFits)
        }
        .accentColor(.blue)
    }
}
