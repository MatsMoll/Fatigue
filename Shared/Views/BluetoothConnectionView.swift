//
//  BluetoothConnectionView.swift
//  Fatigue
//
//  Created by Mats Mollestad on 10/06/2021.
//

import SwiftUI
import Combine
import CoreBluetooth

//struct BluetoothConnectionView: View {
//
//    let bluetoothDeviceType: BluetoothDeviceType
//
//    @EnvironmentObject
//    var manager: BluetoothManager
//
//    var discoverer: BluetoothDeviceDiscoverer { manager.deviceDiscoverer }
//
//    @State
//    var error: Error? = nil
//
//    @State
//    var availableDevices: [ConnectableBluetoothDevice] = []
//
//    @State
//    var sensorState: BluetoothSensorState = .unknown
//
//    @Environment(\.presentationMode)
//    var presentationMode
//
//    var body: some View {
//        VStack {
//
//            if sensorState != .poweredOn {
//                Text("Waiting for bluetooth to turn on")
//            } else {
//                ProgressView("Searching...")
//                    .progressViewStyle(CircularProgressViewStyle())
//                    .padding()
//                    .onAppear {
//                        do {
//                            try manager.discoverDevices(bluetoothDeviceType)
//                        } catch {
//                            print("Error: \(error)")
//                            self.error = error
//                        }
//                    }
//            }
//
//            List(availableDevices.sorted(by: { $0.name < $1.name }), id: \.id) { device in
//                if device.state == .connecting {
//                    ProgressView()
//                        .progressViewStyle(CircularProgressViewStyle())
//                } else if device.state == .connected {
//                    Image(symbol: .checkmark)
//                }
//
//                Label(device.name, systemImage: device.type.systemImage)
//                    .id(device.id)
//                    .onTapGesture {
//                        print(device.id)
//                        try? manager.connect(to: device)
//                    }
//            }
//
//            #if os(OSX)
//            Button("Close") {
//                presentationMode.wrappedValue.dismiss()
//            }
//            .keyboardShortcut(.cancelAction)
//            #endif
//        }
//        .toolbar {
//            #if os(iOS)
//            ToolbarItem(placement: .automatic) {
//                Button("Close") {
//                    presentationMode.wrappedValue.dismiss()
//                }
//                .keyboardShortcut(.cancelAction)
//            }
//            #endif
//        }
//        .navigationTitle("Connect Devices")
//        .frame(minWidth: 300, minHeight: 260)
//        .onDisappear(perform: {
//            discoverer.stopSearch()
//        })
//        .onReceive(discoverer.onUpdatedValues, perform: { devices in
//            self.availableDevices = devices
//        })
//        .onReceive(discoverer.sensorStateChanged, perform: { state in
//            self.sensorState = state
//        })
//    }
//}
//
//struct BluetoothConnectionView_Previews: PreviewProvider {
//    static var previews: some View {
//        BluetoothConnectionView(bluetoothDeviceType: .heartRate, error: nil)
//            .environmentObject(BluetoothManager())
//    }
//}
