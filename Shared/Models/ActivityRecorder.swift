//
//  ActivityRecorder.swift
//  Fatigue
//
//  Created by Mats Mollestad on 10/06/2021.
//

import Foundation
import Combine

class ActivityRecorderCollector {
    
    var isRecording = false
    
    private var timestamp: Int = 0
    
    // Heart Rate Values
    private var newHeartRate: Int?
    private var newRRIntervals: [Int] = []
    
    private var heartBeatListner: AnyCancellable?
    private var rrIntervallListner: AnyCancellable?
    
    // Power Values
    private var newPower: Int?
    
    private var powerListner: AnyCancellable?
    
    private var prevValues: Workout.DataFrame = .init(timestamp: 0)
    
    private let dfaAlphaStream: DFAStreamModel
    
    var numberOfArtifactsRemoved: Int {
        dfaAlphaStream.numberOfArtifactsRemoved
    }
    
    var artifactCorrectionSetting: Double {
        dfaAlphaStream.artifactCorrectionThreshold
    }
    
    var hasHeartRateConnection: Bool { manager.hasConnected(to: .heartRate) }
    
    var hasPowerMeterConnection: Bool { manager.hasConnected(to: .powerMeter) }
    
    let manager: BluetoothManager
    
    private var recordTimer: Timer?
    
    let lockQueue = DispatchQueue(label: "activity.recorder")
    
    init(
        manager: BluetoothManager,
        settings: UserSettings,
        onNewFrame: @escaping (Workout.DataFrame, Int) -> Void
    ) {
        self.manager = manager
        self.dfaAlphaStream = .init(
            artifactCorrectionThreshold: settings.artifactCorrection,
            windowDuration: settings.dfaWindow
        )
        
        let heartRateHandler = BluetoothHeartRateHandler()
        register(heartBeatHandler: heartRateHandler)
        manager.register(handler: heartRateHandler, for: .heartRate)
        
        let powerHandler = BluetoothPowerHandler()
        register(powerHandler: powerHandler)
        manager.register(handler: powerHandler, for: .powerMeter)
        
        recordTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.lockQueue.async {
                guard let newFrame = self?.collectFrame(), let numberOfArtifactsRemoved = self?.numberOfArtifactsRemoved else { return }
                onNewFrame(newFrame, numberOfArtifactsRemoved)
            }
        }
    }
    
    func register(powerHandler: PowerHandler) {
        powerListner = powerHandler.powerPublisher
            .sink(receiveValue: { [weak self] power in
                self?.newPower = power
            })
    }
    
    func register(heartBeatHandler: HeartBeatHandler) {
        heartBeatListner = heartBeatHandler.heartRatePublisher
            .receive(on: lockQueue)
            .sink(receiveValue: { [weak self] bpm in
                self?.newHeartRate = bpm
            })
        rrIntervallListner = heartBeatHandler.rrIntervalPublisher
            .receive(on: lockQueue)
            .sink(receiveValue: { [weak self] rrInterval in
                self?.newRRIntervals.append(rrInterval)
                self?.dfaAlphaStream.add(value: rrInterval)
            })
    }
    
    func resetValues() {
        newHeartRate = nil
        newRRIntervals = []
        newPower = nil
    }
    
    func collectFrame() -> Workout.DataFrame {
        let dfaValue = try? dfaAlphaStream.compute().beta
        timestamp = timestamp + (isRecording ? 1 : 0)
        let newFrame = Workout.DataFrame(
            timestamp: timestamp,
            heartRate: newHeartRate ?? prevValues.heartRate,
            power: newPower ?? prevValues.power,
            cadence: nil,
            dfaAlpha1: dfaValue ?? prevValues.dfaAlpha1,
            rrIntervals: newRRIntervals.isEmpty ? nil : newRRIntervals,
            ratingOfPervicedEffort: nil
        )
        resetValues()
        prevValues = newFrame
        return newFrame
    }
    
    func startRecording() {
        isRecording = true
    }
    
    func pauseRecording() {
        isRecording = false
    }
    
    func stopRecording() {
        pauseRecording()
        timestamp = 0
        prevValues = .init(timestamp: 0)
        resetValues()
    }
}

struct ActivityRecorder {
    
    var workoutID: UUID
    
    var startedAt: Date
    
    var recordedData: [Workout.DataFrame] = []
    
    var currentFrame: Workout.DataFrame = .init(timestamp: 0)
    
    var totalNumberOfRRIntervals = 0
    
    var numberOfArtifactsRemoved: Int = 0
    
    var artifactsPercentage: Double {
        guard totalNumberOfRRIntervals != 0 else { return 0 }
        return Double(numberOfArtifactsRemoved) / Double(totalNumberOfRRIntervals)
    }
    
    var workout: Workout {
        .init(
            id: workoutID,
            startedAt: startedAt,
            values: recordedData,
            powerCurve: nil
        )
    }
    
    mutating func record(frame: Workout.DataFrame) {
        if let rrIntervals = frame.rrIntervals {
            totalNumberOfRRIntervals += rrIntervals.count
        }
        if frame.timestamp > currentFrame.timestamp {
            recordedData.append(currentFrame)
        }
        currentFrame = frame
    }
}
