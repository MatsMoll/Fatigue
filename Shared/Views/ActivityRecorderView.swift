//
//  ActivityRecorderView.swift
//  Fatigue
//
//  Created by Mats Mollestad on 10/06/2021.
//

import SwiftUI

struct ActivityRecorderView: View {
    
    @EnvironmentObject var model: AppModel
    
    @State
    var connectToDeviceType: BluetoothDeviceType?
    
    static let formatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute, .second]
        return formatter
    }()
    
    var body: some View {
        ScrollView {
            VStack {
                ValueView(
                    title: "Elapsed Time",
                    value: Self.formatter.string(from: Double(model.recorder.currentFrame.timestamp)) ?? ""
                )
                
                if model.recorderCollector.hasHeartRateConnection {
                    ValueView(
                        title: "Heart Rate",
                        value: "\(model.recorder.currentFrame.heartRate ?? 0)"
                    )
                    
                    ValueView(
                        title: "Number Of Artifacts Removed",
                        value: "\(model.recorder.numberOfArtifactsRemoved) (\(Int(model.recorder.artifactsPercentage * 100))%)"
                    )
                    
                    ValueView(
                        title: "DFA Alpha 1",
                        value: "\(model.recorder.currentFrame.dfaAlpha1 ?? 0)"
                    )
                } else {
                    Button("Connect Heart Rate") {
                        connectToDeviceType = .heartRate
                    }
                    .padding()
                }
                
                if model.recorderCollector.hasPowerMeterConnection {
                    ValueView(
                        title: "Power",
                        value: "\(model.recorder.currentFrame.power ?? 0)"
                    )
                } else {
                    Button("Connect Power Meter") {
                        connectToDeviceType = .powerMeter
                    }
                    .padding()
                }
                
                Button {
                    if model.recorderCollector.isRecording {
                        model.recorderCollector.pauseRecording()
                    } else {
                        model.recorderCollector.startRecording()
                    }
                } label: {
                    Image(symbol: model.recorderCollector.isRecording ? .pauseFill : .playFill)
                }
                .padding()
                
                Button(action: saveWorkout) {
                    Label("Stop and Save", symbol: .stopCircleFill)
                }
                .padding()
            }
        }
        .navigationTitle("Record")
        .sheet(item: $connectToDeviceType) { type in
            #if os(iOS)
            NavigationView {
                BluetoothConnectionView(
                    connector: try! model.bluetoothManager.connector(for: type)
                )
            }
            #elseif os(OSX)
            BluetoothConnectionView(
                connector: try! recorder.manager.connector(for: type)
            )
            #endif
        }
    }
    
    func saveWorkout() {
        model.saveRecordedActivity()
    }
}

struct ActivityRecorderView_Previews: PreviewProvider {
    static var previews: some View {
        ActivityRecorderView(
            connectToDeviceType: nil
        )
    }
}
