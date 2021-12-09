//
//  ContentView.swift
//  WatchOS Extension
//
//  Created by Mats Mollestad on 24/06/2021.
//

import SwiftUI
import HealthKit
import WatchConnectivity

class ActivityModel: NSObject, ObservableObject, WCSessionDelegate {
    
    @Published
    var currentFrame: WorkoutFrame?
    
    @Published
    var recorderState: RecordingState = .pause
    
    let healthStore = HKHealthStore()
    var workoutSession: HKWorkoutSession?
    var builder: HKLiveWorkoutBuilder?
    
    
    @Published
    var error: Error?
    
    let decoder = JSONDecoder()
    
    var elapsedTime: String {
        guard let timestamp = currentFrame?.timestamp else { return "0" }
        return dateFormatter.string(from: Double(timestamp)) ?? "\(timestamp)"
    }
    
    var dfaValue: String? {
        guard let value = currentFrame?.heartRate?.dfaAlpha1 else { return nil }
        return NumberFormatter.defaultFormatter.string(from: .init(value: value)) ?? "\(value)"
    }
    
    let dateFormatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute, .second]
        return formatter
    }()
    
    init(watchSession: WCSession = .default) {
        super.init()
        let workoutConfig = HKWorkoutConfiguration()
        workoutConfig.activityType = .cycling
        workoutConfig.locationType = .unknown
        workoutSession = try? HKWorkoutSession(healthStore: healthStore, configuration: workoutConfig)
        workoutSession?.startActivity(with: .init())
        workoutSession?.resume()
        watchSession.delegate = self
        watchSession.activate()
//        let startDate = Date()
//        workoutSession?.startActivity(with: startDate)
//        builder = workoutSession?.associatedWorkoutBuilder()
//
//        builder?.delegate = self
//        watchSession.delegate = self
//
//        // Set the workout builder's data source.
//        builder?.dataSource = HKLiveWorkoutDataSource(healthStore: healthStore, workoutConfiguration: workoutConfig)
//        builder?.beginCollection(withStart: startDate) { (success, error) in
//            // The workout has started.
//        }
    }
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        DispatchQueue.main.async { [weak self] in
            self?.error = error
        }
    }
    
    func session(_ session: WCSession, didReceiveMessageData messageData: Data) {
        do {
            let message = try decoder.decode(WatchMessage.self, from: messageData)
//            if recorderState != message.recordingState {
//                switch message.recordingState {
//                case .recording: workoutSession?.resume()
//                case .pause: workoutSession?.pause()
//                case .stop: workoutSession?.end()
//                }
//            }
            DispatchQueue.main.async { [weak self] in
                self?.recorderState = message.recordingState
                self?.currentFrame = message.frame
                self?.error = nil
            }
        } catch {
            DispatchQueue.main.async { [weak self] in
                self?.error = error
            }
        }
    }
    
    // Request authorization to access HealthKit.
    func requestAuthorization() {
        // The quantity type to write to the health store.
        let typesToShare: Set = [
            HKQuantityType.workoutType()
        ]

        // The quantity types to read from the health store.
        let typesToRead: Set = [
            HKQuantityType.quantityType(forIdentifier: .heartRate)!,
        ]

        // Request authorization for those quantity types.
        healthStore.requestAuthorization(toShare: typesToShare, read: typesToRead) { (success, error) in
            // Handle error.
        }
    }
}

extension ActivityModel: HKWorkoutSessionDelegate {
    func workoutSession(_ workoutSession: HKWorkoutSession, didChangeTo toState: HKWorkoutSessionState, from fromState: HKWorkoutSessionState, date: Date) {
        print("Did change State: \(toState)")
    }
    
    func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: Error) {
        
    }
    
    
}

extension ActivityModel: HKLiveWorkoutBuilderDelegate {
    func workoutBuilderDidCollectEvent(_ workoutBuilder: HKLiveWorkoutBuilder) {
        
    }
    
    func workoutBuilder(_ workoutBuilder: HKLiveWorkoutBuilder, didCollectDataOf collectedTypes: Set<HKSampleType>) {
        
    }
}

struct ActivityView: View {
    
    @EnvironmentObject
    var model: ActivityModel
    
    var body: some View {
        ScrollView {
            VStack {
                if let error = model.error {
                    Text("Ups! An error occured")
                        .font(.title)
                        .foregroundColor(.primary)
                    Text(error.localizedDescription)
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                
                if let frame = model.currentFrame {
                    
                    ValueView(
                        title: "Elapsed Time",
                        value: model.elapsedTime,
                        symbol: .clock,
                        imageColor: .secondary
                    )
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    if let dfaValue = model.dfaValue {
                        ValueView(
                            title: "DFA Alpha 1",
                            value: dfaValue,
                            symbol: .heartFill,
                            imageColor: .purple
                        )
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    
                    if let bpm = frame.heartRate {
                        ValueView(
                            title: "Heart Rate",
                            value: "\(bpm)",
                            symbol: .heartFill,
                            imageColor: .red
                        )
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    
                    if let power = frame.power {
                        ValueView(
                            title: "Power",
                            value: "\(power)",
                            symbol: .boltFill,
                            imageColor: .blue
                        )
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    
                } else {
                    Text("Start an activity on your phone")
                }
            }
        }
//        .onAppear(perform: {
//            model.requestAuthorization()
//        })
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ActivityView()
    }
}
