//
//  DeciveTypesView.swift
//  DeciveTypesView
//
//  Created by Mats Mollestad on 04/09/2021.
//

import SwiftUI

struct DeviceTypesView: View {
    
    @State
    var deviceDiscoverer: IdentifiableDeviceDiscoverer?
    
    @Binding
    var shouldPresentList: Bool
    
    let deviceTypes: [DeviceType]
    
    @Environment(\.horizontalSizeClass)
    var horizontalSizeClass
    
    @EnvironmentObject
    var recorder: ActivityRecorder
    
    var columns: [GridItem] {
        if horizontalSizeClass == .regular {
            return [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ]
        } else {
            return [
                GridItem(.flexible()),
                GridItem(.flexible())
            ]
        }
    }
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns) { deviceList }
                .padding()
        }
        .sheet(item: $deviceDiscoverer) { deviceDiscoverer in
            connectableDeviceList(discoverer: deviceDiscoverer.discoverer)
        }
        .navigationTitle("Devices")
        .navigationBarItems(trailing: cancelButton)
        .onAppear { recorder.stopObservingValues() }
        .onDisappear { recorder.startObservingValues() }
    }
    
    var cancelButton: some View {
        Button("Cancel") {
            shouldPresentList = false
        }
    }
    
    var deviceList: some View {
        ForEach(deviceTypes, id: \.id) { type in
            DeviceCard(
                device: recorder.device(for: type),
                type: type,
                deviceDiscoverer: $deviceDiscoverer
            )
            .roundedButton(color: .init(.secondarySystemBackground))
        }
    }
    
    func connectableDeviceList(discoverer: DeviceDiscoverer) -> some View {
        
        let listner = ConnectionListner(deviceManager: recorder.deviceManager)
        
        return NavigationView {
            ConnectableDevicesListView(
                discoverer: discoverer,
                deviceListner: listner,
                shouldBePresentet: Binding<Bool>(
                    get: { deviceDiscoverer != nil },
                    set: { newValue in
                        if newValue == false {
                            deviceDiscoverer = nil
                        }
                    }
                )
            )
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

struct DeviceTypesView_Previews: PreviewProvider {
    
    static let connectedRecorder: ActivityRecorder = {
        let deviceManager = DeviceManager()
        deviceManager.powerDevice = PowerDeviceWrapper(
            device: BluetoothDeviceMock(
                id: .init(),
                name: "Mats's Power Meter",
                type: .powerMeter,
                state: .connected,
                onValueCharecteristic: .cyclingPowerMeasurement
            ),
            powerHandler: BluetoothPowerHandlerMock()
        )
        return ActivityRecorder(settings: .init(), deviceManager: deviceManager)
    }()
    
    static var previews: some View {
        Group {
            NavigationView {
                DeviceTypesView(
                    deviceDiscoverer: nil,
                    shouldPresentList: .constant(true),
                    deviceTypes: [
                        BluetoothDeviceType.powerMeterMock,
                    ]
                )
            }
            .environmentObject(ActivityRecorder(settings: .init()))
            NavigationView {
                DeviceTypesView(
                    deviceDiscoverer: nil,
                    shouldPresentList: .constant(true),
                    deviceTypes: [
                        BluetoothDeviceType.powerMeterMock,
                    ]
                )
            }
            .environmentObject(connectedRecorder)
        }
    }
}

