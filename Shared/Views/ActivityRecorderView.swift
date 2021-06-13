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
            VStack(spacing: 18) {
                ValueView(
                    title: "Elapsed Time",
                    value: Self.formatter.string(from: Double(model.recorder.currentFrame.timestamp)) ?? "",
                    symbol: .clock,
                    imageColor: .primary
                )
                .frame(maxWidth: .infinity, alignment: .leading)
                
                if model.recorderCollector.hasHeartRateConnection {
                    ValueView(
                        title: "Heart Rate",
                        value: "\(model.recorder.currentFrame.heartRate ?? 0) bpm",
                        symbol: .heartFill,
                        imageColor: .red
                    )
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    ValueView(
                        title: "Number Of Artifacts Removed - with: \(model.recorderCollector.artifactCorrectionSetting)",
                        value: "\(model.recorder.numberOfArtifactsRemoved) (\(Int(model.recorder.artifactsPercentage * 100))%)"
                    )
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    ValueView(
                        title: "DFA Alpha 1",
                        value: "\(model.recorder.currentFrame.dfaAlpha1 ?? 0)",
                        symbol: .heartFill,
                        imageColor: .purple
                    )
                    .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    Button("Connect Heart Rate") {
                        connectToDeviceType = .heartRate
                    }
                    .padding()
                }
                
                if model.recorderCollector.hasPowerMeterConnection {
                    ValueView(
                        title: "Power",
                        value: "\(model.recorder.currentFrame.power ?? 0) watts",
                        symbol: .boltFill,
                        imageColor: .blue
                    )
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    if let cadence = model.recorder.currentFrame.cadence {
                        ValueView(
                            title: "Cadence",
                            value: "\(cadence) rpm",
                            symbol: .goForwared,
                            imageColor: .orange
                        )
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
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
                    VStack {
                        Image(symbol: model.recorderCollector.isRecording ? .pauseFill : .playFill)
                            .font(.title)
                        
                        Text(model.recorderCollector.isRecording ? "Pause" : "Start")
                    }
                }
                .padding()
                
                if !model.recorder.recordedData.isEmpty {
                    Button(action: saveWorkout) {
                        VStack {
                            Image(symbol: .stopCircleFill)
                                .font(.title)
                            
                            Text("Stop and Save")
                        }
                    }
                    .padding()
                }
            }
            .padding()
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
                connector: try! model.bluetoothManager.connector(for: type)
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
