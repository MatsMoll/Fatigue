//
//  BluetoothConnectionView.swift
//  Fatigue
//
//  Created by Mats Mollestad on 10/06/2021.
//

import SwiftUI
import Combine
import CoreBluetooth

struct BluetoothConnectionView: View {
    
    @ObservedObject
    var connector: BluetoothConnector
    
    @State
    var error: Error?
    
    @Environment(\.presentationMode)
    var presentationMode
    
    var body: some View {
        VStack {
            
            if connector.managerState != .poweredOn {
                Text("Waiting for bluetooth to turn on")
            } else {
                ProgressView("Searching...")
                    .progressViewStyle(CircularProgressViewStyle())
                    .padding()
                    .onAppear {
                        do {
                            try connector.startScanning()
                        } catch {
                            print("Error: \(error)")
                            self.error = error
                        }
                    }
            }
            
            List(connector.devices.sorted(by: { $0.name < $1.name })) { device in
                if connector.focusedDevice == device {
                    if connector.focusedDevice?.state == .connecting {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                    } else if connector.focusedDevice?.state == .connected {
                        Image(symbol: .checkmark)
                    }
                }
                Label(device.name, systemImage: device.type.systemImage)
                    .id(device)
                    .onTapGesture {
                        connector.connect(to: device)
                    }
            }
            
            #if os(OSX)
            Button("Close") {
                presentationMode.wrappedValue.dismiss()
            }
            .keyboardShortcut(.cancelAction)
            #endif
        }
        .toolbar {
            #if os(iOS)
            ToolbarItem(placement: .automatic) {
                Button("Close") {
                    presentationMode.wrappedValue.dismiss()
                }
                .keyboardShortcut(.cancelAction)
            }
            #endif
        }
        .navigationTitle("Connect Devices")
        .frame(minWidth: 300, minHeight: 260)
    }
}

struct BluetoothConnectionView_Previews: PreviewProvider {
    static var previews: some View {
        BluetoothConnectionView(
            connector: .init(central: .init(), type: .heartRate, handler: BluetoothHeartRateHandler()),
            error: nil
        )
    }
}
