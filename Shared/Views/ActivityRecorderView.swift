//
//  ActivityRecorderView.swift
//  Fatigue
//
//  Created by Mats Mollestad on 10/06/2021.
//

import SwiftUI


struct ActivityRecorderView: View {
    
    @EnvironmentObject var model: AppModel
//    @EnvironmentObject var recorder: ActivityRecorderCollector
//    @EnvironmentObject var garminDeviceManager: GarminDeviceListViewModel
    
    @State
    var shouldPresentDevices: Bool = false
    
    static let formatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute, .second]
        return formatter
    }()
    
    var body: some View {
        ScrollView {
            Text("Hello")
//            VStack(spacing: 18) {
//                ValueView(
//                    title: "Elapsed Time",
//                    value: Self.formatter.string(from: Double(recorder.recorder.currentFrame.timestamp)) ?? "",
//                    symbol: .clock,
//                    imageColor: .primary
//                )
//                .frame(maxWidth: .infinity, alignment: .leading)
//
//                if recorder.hasHeartRateConnection {
//                    ValueView(
//                        title: "Heart Rate",
//                        value: "\(recorder.recorder.currentFrame.heartRate ?? 0) bpm",
//                        symbol: .heartFill,
//                        imageColor: .red
//                    )
//                    .frame(maxWidth: .infinity, alignment: .leading)
//
//                    ValueView(
//                        title: "Number Of Artifacts Removed - with: \(recorder.artifactCorrectionSetting)",
//                        value: "\(recorder.recorder.numberOfArtifactsRemoved) (\(Int(recorder.recorder.artifactsPercentage * 100))%)"
//                    )
//                    .frame(maxWidth: .infinity, alignment: .leading)
//
//                    ValueView(
//                        title: "DFA Alpha 1",
//                        value: "\(recorder.recorder.currentFrame.dfaAlpha1 ?? 0)",
//                        symbol: .heartFill,
//                        imageColor: .purple
//                    )
//                    .frame(maxWidth: .infinity, alignment: .leading)
//                } else {
//                    Button("Connect Heart Rate") {
//                        connectToDeviceType = .heartRate
//                    }
//                    .padding()
//                }
//
//                if recorder.hasPowerMeterConnection {
//                    ValueView(
//                        title: "Power",
//                        value: "\(recorder.recorder.currentFrame.power ?? 0) watts",
//                        symbol: .boltFill,
//                        imageColor: .blue
//                    )
//                    .frame(maxWidth: .infinity, alignment: .leading)
//
//                    if let powerBalance = recorder.recorder.currentFrame.powerBalance {
//                        ValueView(
//                            title: "Power Balance",
//                            value: powerBalance.description(),
//                            symbol: .arrowtriangleAndLineVertical,
//                            imageColor: .blue
//                        )
//                        .frame(maxWidth: .infinity, alignment: .leading)
//                    }
//
//                    if let cadence = recorder.recorder.currentFrame.cadence {
//                        ValueView(
//                            title: "Cadence",
//                            value: "\(cadence) rpm",
//                            symbol: .goForwared,
//                            imageColor: .orange
//                        )
//                        .frame(maxWidth: .infinity, alignment: .leading)
//                    }
//                } else {
//                    Button("Connect Power Meter") {
//                        connectToDeviceType = .powerMeter
//                    }
//                    .padding()
//                }
                
//                #if os(iOS)
//                Button("Connect Garmin Device") {
//                    GarminDeviceListViewModel().selectDevice()
//                }
//
//                Button("Send Value") {
//                    garminDeviceManager.send(message: [
//                        "dfa-a1": 0.8 + .random(in: -0.2...0.2)
//                    ])
//                }
//                #endif
                
//                Button {
//                    if recorder.isRecording {
//                        recorder.pauseRecording()
//                    } else {
//                        recorder.startRecording()
//                    }
//                } label: {
//                    VStack {
//                        Image(symbol: recorder.isRecording ? .pauseFill : .playFill)
//                            .font(.title)
//
//                        Text(recorder.isRecording ? "Pause" : "Start")
//                    }
//                }
//                .padding()
                
//                if !recorder.recorder.recordedData.isEmpty {
//                    Button(action: saveWorkout) {
//                        VStack {
//                            Image(symbol: .stopCircleFill)
//                                .font(.title)
//
//                            Text("Stop and Save")
//                        }
//                    }
//                    .padding()
//                }
//            }
//            .padding()
        }
        .navigationTitle("Record")
        .navigationBarItems(trailing: devicesButton)
        .sheet(isPresented: $shouldPresentDevices) { devicesView }
//        .sheet(item: $connectToDeviceType) { type in
//            #if os(iOS)
//            NavigationView {
//                BluetoothConnectionView(bluetoothDeviceType: type)
//            }
//            Text("dd")
//            #elseif os(OSX)
//            BluetoothConnectionView(bluetoothDeviceType: type)
//            #endif
//        }
    }
    
    var devicesView: some View {
        #if DEBUG
        let deviceTypes = [
            BluetoothDeviceType.powerMeterMock
        ]
        #else
        let deviceTypes = [
            BluetoothDeviceType.powerMeter,
            BluetoothDeviceType.heartRate,
        ]
        #endif
        
        return NavigationView {
            DeviceTypesView(
                shouldPresentList: $shouldPresentDevices,
                deviceTypes: deviceTypes
            )
        }
    }
    
    var devicesButton: some View {
        Button("Devices") {
            shouldPresentDevices = true
        }
    }
    
    func saveWorkout() {
//        model.save(recorder: recorder)
    }
}

struct ActivityRecorderView_Previews: PreviewProvider {
    static var previews: some View {
        ActivityRecorderView()
    }
}
