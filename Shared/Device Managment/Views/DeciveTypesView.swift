//
//  DeciveTypesView.swift
//  DeciveTypesView
//
//  Created by Mats Mollestad on 04/09/2021.
//

import SwiftUI
#if os(iOS)
import UIKit
#else
import AppKit
#endif

extension Color {
    static var background: Color {
        #if os(iOS)
        return Color(.secondarySystemBackground)
        #else
        return Color(.windowBackgroundColor)
        #endif
    }
}

struct DeviceTypesView: View {
    
    @State
    var deviceDiscoverer: IdentifiableDeviceDiscoverer?
    
    @Binding
    var shouldPresentList: Bool
    
    let deviceTypes: [DeviceType]
    
    #if os(iOS)
    @Environment(\.horizontalSizeClass)
    var horizontalSizeClass
    #endif
    
    @EnvironmentObject
    var recorder: ActivityRecorder
    
    var columns: [GridItem] {
        #if os(iOS)
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
        #else
        return [
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible()),
        ]
        #endif
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
        #if os(iOS)
        .navigationBarItems(trailing: cancelButton)
        #endif
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
            .roundedButton(color: .background)
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
        #if os(iOS)
        .navigationViewStyle(StackNavigationViewStyle())
        #endif
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

