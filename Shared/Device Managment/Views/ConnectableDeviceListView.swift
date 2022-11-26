//
//  ConnectableDeviceList.swift
//  ConnectableDeviceList
//
//  Created by Mats Mollestad on 04/09/2021.
//

import SwiftUI

struct ConnectableDevicesListView: View {
    
    struct IdentifiableError: Error, Identifiable {
        let id: UUID = .init()
        let error: Error
        
        var localizedDescription: String {
            error.localizedDescription
        }
    }
    
    let discoverer: DeviceDiscoverer
    
    @ObservedObject
    var deviceListner: ConnectionListner
    
    @Binding
    var shouldBePresentet: Bool
    
    @State
    var error: IdentifiableError? = nil
    
    @State
    var devices: [BluetoothDevice] = []
    
    @State
    var state: DeviceDiscovererState = .unknown
    
    @State
    var updater: Bool = false
    
    var body: some View {
        List {
            if state != .poweredOn {
                Text("Sensor state: \(state.description)")
            } else {
                ProgressView("Searching...")
                    .frame(maxWidth: .infinity, alignment: .center)
            }
            ForEach(discoverer.devices, id: \.id) { device in
                ConnectableDeviceCell(device: device)
                    .onTapGesture {
                        connect(to: device)
                    }
            }
        }
        .onAppear(perform: {
            state = discoverer.state
            devices = discoverer.devices
            startLoadingDevices()
        })
        .onReceive(discoverer.onUpdatedValues, perform: { loadedDevices in
            devices = loadedDevices
        })
        .onReceive(discoverer.onUpdatedState, perform: { newState in
            state = newState
            startLoadingDevices()
        })
        .alert(item: $error) { error in
            Alert(
                title: Text("Ups! An error occured"),
                message: Text(error.localizedDescription),
                dismissButton: .default(Text("Ok"))
            )
        }
        .navigationTitle("Connect Device")
        #if os(iOS)
        .listStyle(InsetGroupedListStyle())
        .navigationBarItems(trailing: cancelButton)
        #endif
    }
    
    var cancelButton: some View {
        Button("Cancel") {
            shouldBePresentet = false
        }
    }
    
    func startLoadingDevices() {
        guard state == .poweredOn else { return }
        do {
            try discoverer.startSearch()
        } catch {
            self.error = IdentifiableError(error: error)
        }
    }
    
    func connect(to device: BluetoothDevice) {
        do {
            deviceListner.listen(to: device) { _ in
                shouldBePresentet = false
            }
            try device.connect()
            updater.toggle()
        } catch {
            self.error = IdentifiableError(error: error)
        }
    }
}

struct ConnectableDevicesListView_Previews: PreviewProvider {
    
    static let shownDevices = [
        BluetoothDeviceMock(id: .init(), name: "Mats's Power Meter", type: .powerMeter, state: .connecting, onValueCharecteristic: .cyclingPowerMeasurement),
        BluetoothDeviceMock(id: .init(), name: "Mats's Heart Rate", type: .heartRate, state: .disconnected, onValueCharecteristic: .cyclingPowerMeasurement)
    ]
    
    static var previews: some View {
        Group {
            NavigationView {
                ConnectableDevicesListView(
                    discoverer: DeviceDiscovererMock(
                        devices: shownDevices
                    ),
                    deviceListner: .init(deviceManager: .init()),
                    shouldBePresentet: .constant(true)
                )
            }
            NavigationView {
                ConnectableDevicesListView(
                    discoverer: DeviceDiscovererMock(
                        devices: shownDevices
                    ),
                    deviceListner: .init(deviceManager: .init()),
                    shouldBePresentet: .constant(true),
                    error: .init(error: NSError(domain: "Ups, random error", code: 000, userInfo: nil))
                )
            }
        }
    }
}
