//
//  RecordWorkoutView.swift
//  RecordWorkoutView
//
//  Created by Mats Mollestad on 04/09/2021.
//

import SwiftUI

struct RecordWorkoutView: View {
    
    @EnvironmentObject
    var recorder: ActivityRecorder
    
    var activityFrame: WorkoutFrame {
        recorder.latestFrame
    }
    
    let durationFormatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute, .second]
        return formatter
    }()
    
    @State
    var shouldPresentDevices: Bool = false
    
    @State
    var shouldSave: Bool = false
    
    #if os(iOS)
    @Environment(\.horizontalSizeClass)
    var horizontalSizeClass
    #endif
    
    var columns: [GridItem] {
        #if os(iOS)
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
            LazyVGrid(columns: columns) {
                
                if let lsctResult = recorder.lsctResult {
                    LSCTResultView(lsctResult: .init(lsctResult: lsctResult))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .card()
                }
                
                if recorder.numberOfLaps > 0 {
                    WorkoutValueView(
                        type: .lapNumber,
                        value: "Lap \(recorder.numberOfLaps + 1)"
                    )
                    WorkoutValueView(
                        type: .lapDuration,
                        value: durationFormatter.string(from: TimeInterval(recorder.elapsedRoundTime)) ?? "\(recorder.elapsedRoundTime)"
                    )
                }
                
                WorkoutValueView(
                    type: .duration,
                    value: durationFormatter.string(from: TimeInterval(activityFrame.timestamp)) ?? "\(activityFrame.timestamp)"
                )
                
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
                
                if let cadence = activityFrame.cadence {
                    WorkoutValueView(
                        type: .cadence,
                        value: "\(cadence.value)"
                    )
                }
            }
            .padding()
            
            HStack(spacing: 10) {
                RecorderControllsView(shouldSave: $shouldSave)
            }
            
            if !recorder.deviceManager.hasConnectedDevice {
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
            
            VStack(spacing: 70) {
                ForEach(recorder.lapSummaries.reversed()) { lap in
                    WorkoutLapSummary(workout: recorder.workout, lap: lap)
                }
            }
            .padding()
        }
        #if os(iOS)
        .listStyle(InsetGroupedListStyle())
        .navigationBarItems(trailing: deviceItem)
        #endif
        .navigationTitle("Activity")
        .sheet(isPresented: $shouldPresentDevices) { deviceTypesView }
        .sheet(isPresented: $shouldSave) { savingView }
        .onAppear(perform: { recorder.startObservingValues() })
        .onDisappear { recorder.stopObservingValues() }
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
        SavingWorkoutView(shouldPresentSaving: $shouldSave)
    }
}

struct RecordWorkoutView_Previews: PreviewProvider {
    static var previews: some View {
        RecordWorkoutView()
    }
}
