//
//  RecordWorkoutView.swift
//  RecordWorkoutView
//
//  Created by Mats Mollestad on 04/09/2021.
//

import SwiftUI

struct RecordWorkoutView: View {
    
    @EnvironmentObject
    var recoder: ActivityRecorder
    
    var activityFrame: WorkoutFrame {
        recoder.latestFrame
    }
    
    @State
    var shouldPresentDevices: Bool = false
    
    @State
    var shouldSave: Bool = false
    
    @Environment(\.horizontalSizeClass)
    var horizontalSizeClass
    
    var columns: [GridItem] {
        if horizontalSizeClass == .regular {
            return [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible()),
            ]
        } else {
            return [
                GridItem(.flexible()),
            ]
        }
    }
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns) {
                
                WorkoutValueView(
                    type: .duration,
                    value: "\(activityFrame.timestamp)"
                )
                
                if let heartRate = activityFrame.heartRate {
                 
                    WorkoutValueView(
                        type: .heartRate,
                        value: "\(heartRate.value)"
                    )
                    
                    if let dfaAlpha1 = heartRate.dfaAlpha1 {
                        WorkoutValueView(
                            type: .dfaAlpha1,
                            value: "\(dfaAlpha1)"
                        )
                    }
                }
                
                if let power = activityFrame.power {
                    WorkoutValueView(
                        type: .power,
                        value: "\(power.value)"
                    )
                    
                    if let balance = power.balance {
                        WorkoutValueView(
                            type: .powerBalance,
                            value: balance.description()
                        )
                    }
                }
                
                if let cadence = activityFrame.cadence {
                    WorkoutValueView(
                        type: .cadence,
                        value: "\(cadence.value)"
                    )
                }
            }
            .padding()
            
            HStack {
                RecorderControllsView(shouldSave: $shouldSave)
            }
            
            if !recoder.deviceManager.hasConnectedDevice {
                VStack {
                    Text("You have no devices connected yet")
                        .foregroundColor(.secondary)
                    
                    Button("Connect a Device") {
                        shouldPresentDevices = true
                    }
                    .roundedButton(color: .secondary)
                    .foregroundColor(.primary)
                }
                .padding()
            }
        }
        .listStyle(InsetGroupedListStyle())
        .navigationTitle("Activity")
        .navigationBarItems(trailing: deviceItem)
        .sheet(isPresented: $shouldPresentDevices) { deviceTypesView }
        .sheet(isPresented: $shouldSave) { savingView }
        .onAppear(perform: { recoder.startObservingValues() })
        .onDisappear { recoder.stopObservingValues() }
    }
    
    var deviceItem: some View {
        Button("Devices") {
            shouldPresentDevices = true
        }
    }
    
    var deviceTypesView: some View {
        return NavigationView {
            DeviceTypesView(
                shouldPresentList: $shouldPresentDevices,
                deviceTypes: supportedDevices
            )
        }
    }
    
    var supportedDevices: [DeviceType] {
        #if DEBUG
        return [
            BluetoothDeviceType.powerMeterMock
        ]
        #else
        return [
            BluetoothDeviceType.powerMeter,
            BluetoothDeviceType.heartRate
        ]
        #endif
    }
    
    var savingView: some View {
        SavingWorkoutView(
            shouldPresentSaving: $shouldSave,
            viewModel: .init()
        )
    }
}

struct RecordWorkoutView_Previews: PreviewProvider {
    static var previews: some View {
        RecordWorkoutView()
    }
}
