//
//  ActivityRecorder.swift
//  Fatigue
//
//  Created by Mats Mollestad on 10/06/2021.
//

import Foundation
import Combine
#if os(iOS)
import WatchConnectivity
#endif

class DeviceManager: ObservableObject {
    
    struct DeviceValues {
        var power: PowerDeviceValue?
        var heartRate: HeartRateDeviceValue?
        
        func frame(timestamp: Int) -> WorkoutFrame {
            var buffer = WorkoutFrame.Mutable(timestamp: timestamp)
            if let power = power {
                buffer.power = .init(
                    value: power.power,
                    balance: power.balence
                )
                buffer.cadence = power.cadence.map(WorkoutFrame.Cadence.init(value: ))
            }
            if let heartRate = heartRate {
                buffer.heartRate = .init(
                    value: heartRate.heartRate,
                    rrIntervals: heartRate.rrIntervals,
                    dfaAlpha1: nil
                )
            }
            return buffer.frame
        }
    }
    
    var hasConnectedDevice: Bool { allDevices.contains(where: { $0 != nil }) }
    var allDevices: [Device?] { [powerDevice, heartRateDevice] }
    
    var currentValues: DeviceValues = .init()
    
    private var powerDeviceListners: Set<AnyCancellable> = []
    private var heartRateListners: Set<AnyCancellable> = []
    
    var powerDevice: PowerDevice? {
        willSet { powerDeviceListners = [] }
        didSet {
            guard let power = powerDevice else { return }
            powerDeviceListners = [
                power.powerListner.sink(receiveValue: { [weak self] values in
                    self?.currentValues.power = values
                }),
                power.didDisconnect.sink(receiveValue: { [weak self] _ in
                    self?.powerDevice = nil
                })
            ]
        }
    }
    var heartRateDevice: HeartRateDevice? {
        willSet { heartRateListners = [] }
        didSet {
            guard let heartRate = heartRateDevice else { return }
            heartRateListners = [
                heartRate.heartRateListner.sink(receiveValue: { [weak self] values in
                    self?.currentValues.heartRate = values
                }),
                heartRate.didDisconnect.sink(receiveValue: { [weak self] _ in
                    self?.heartRateDevice = nil
                })
            ]
        }
    }
}

/// This class will record a workout
/// This inclueds the raw data frames values, potential derived data (dfa alpha 1, lsct etc), hold devices
class ActivityRecorder: ObservableObject {
    
    var startedAt: Date?
    var elapsedTime: Int
    var recordedFrames: [WorkoutFrame]
    
    @Published
    var latestFrame: WorkoutFrame
    
    @Published
    var isRecording: Bool = false
    
    var isObservingValues: Bool = false
    
    var hasValues: Bool { !recordedFrames.isEmpty }
    
    var deviceManager: DeviceManager
    
    lazy var timer: Timer = {
        return Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.recordFrame()
        }
    }()
    
    init(deviceManager: DeviceManager = .init()) {
        self.deviceManager = deviceManager
        recordedFrames = []
        elapsedTime = 0
        let startFrame = WorkoutFrame.Mutable(timestamp: 0)
        deviceManager.currentValues = .init()
        latestFrame = startFrame.frame
    }
    
    func startObservingValues() {
        // Start the timer
        guard timer.isValid else {
            print("Timer is not valid")
            return
        }
        isObservingValues = true
    }
    
    func stopObservingValues() {
        isObservingValues = false
        print("Stop observing")
    }
    
    func startRecording() {
        isRecording = true
        print("Starting recording")
        guard startedAt == nil else { return }
        startedAt = .init()
    }
    
    func pauseRecording() {
        print("Paused Recording")
        isRecording = false
    }
    
    func stopRecording() -> Workout? {
        guard let startedAt = startedAt else { return nil }
        return Workout(
            id: .init(),
            startedAt: startedAt,
            values: recordedFrames
        )
    }
    
    func resetRecorder() {
        isRecording = false
        recordedFrames = []
        elapsedTime = 0
        let startFrame = WorkoutFrame.Mutable(timestamp: 0)
        deviceManager.currentValues = .init()
        latestFrame = startFrame.frame
        startedAt = nil
    }
    
    private func recordFrame() {
        let newFrame = deviceManager.currentValues.frame(timestamp: elapsedTime)
        if isObservingValues {
            latestFrame = newFrame
        }
        
        // Derived data should be computed here
        
        guard isRecording else { return }
        recordedFrames.append(newFrame)
        elapsedTime += 1
        deviceManager.currentValues = .init()
    }
    
    func device(for type: DeviceType) -> Device? {
        switch type.id {
        case BluetoothDeviceType.powerMeter.id: return deviceManager.powerDevice
        case BluetoothDeviceType.heartRate.id: return deviceManager.heartRateDevice
        default: return nil
        }
    }
}

///// Has the purpuse to collect raw stream data and convert it into
///// A more maintainable format
//class ActivityRecorderCollector: ObservableObject {
//
//    var isRecording = false
//
//    private var timestamp: Int = 0
//
//    // Heart Rate Values
//    private var newHeartRate: Int?
//    private var newRRIntervals: [Double] = []
//
//    private var heartBeatListner: AnyCancellable?
//    private var rrIntervallListner: AnyCancellable?
//
//    // Power Values
//    private var newPower: Int?
//
//    private var newPowerBalance: PowerBalance?
//
//    private var powerListner: AnyCancellable?
//
//    private var powerBalanceListner: AnyCancellable?
//
//    // Cadence Values
//    private var newCadence: Int?
//
//    private var cadenceListner: AnyCancellable?
//
//    private var prevValues: Workout.DataFrame = .init(timestamp: 0)
//
//    private let dfaAlphaStream: DFAStreamModel
//
//    private var lsctDetector: LSCTStreamDetector?
//
//    @Published
//    private(set) var lsctDetection: LSCTDetector.Detection?
//
//    private var settingsDFAThreshold: Double?
//
//    var numberOfArtifactsRemoved: Int {
//        dfaAlphaStream.numberOfArtifactsRemoved
//    }
//
//    var artifactCorrectionSetting: Double {
//        dfaAlphaStream.artifactCorrectionThresholdValue
//    }
//
//    var hasHeartRateConnection: Bool { manager.has(connected: .heartRate) }
//    var hasPowerMeterConnection: Bool { manager.has(connected: .powerMeter) }
//
//    let manager: BluetoothManager
//
//    #if os(iOS)
//    class WatchDelegate: NSObject, WCSessionDelegate {
//        func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
//            print("activationDidCompleteWith, \(activationState), error: \(error)")
//        }
//
//        func sessionDidBecomeInactive(_ session: WCSession) {
//            print("sessionDidBecomeInactive")
//        }
//
//        func sessionDidDeactivate(_ session: WCSession) {
//            print("sessionDidDeactivate")
//        }
//    }
//
//    let watchDelegate: WatchDelegate = WatchDelegate()
//    let watchSession: WCSession
//    let encoder = JSONEncoder()
//    #endif
//
//    var baselineWorkoutID: UUID?
//
//    @Published
//    var recorder: ActivityRecorder
//
//    private var recordTimer: Timer?
//
//    let lockQueue = DispatchQueue(label: "activity.recorder")
//
//    init(manager: BluetoothManager, settings: UserSettings, activityRecorder: ActivityRecorder) {
//        self.manager = manager
//        self.settingsDFAThreshold = settings.artifactCorrection
//        #if os(iOS)
//        watchSession = .default
//        watchSession.delegate = watchDelegate
//        watchSession.activate()
//        #endif
//        self.dfaAlphaStream = .init(
//            artifactCorrectionThreshold: settings.artifactCorrectionThreshold,
//            windowDuration: settings.dfaWindow
//        )
//        if let ftp = settings.ftp {
//            self.lsctDetector = LSCTStreamDetector(
//                stages: .defaultWith(ftp: Double(ftp)),
//                threshold: 0.4
//            )
//        } else {
//            self.lsctDetector = nil
//        }
//        self.recorder = activityRecorder
//        self.baselineWorkoutID = settings.baselineWorkoutID
//
//        let heartRateHandler = BluetoothHeartRateHandler()
//        register(heartBeatHandler: heartRateHandler)
//        manager.register(handler: heartRateHandler, for: .heartRate)
//
//        let powerHandler = BluetoothPowerHandler()
//        register(powerHandler: powerHandler)
//        manager.register(handler: powerHandler, for: .powerMeter)
//
//        recordTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
//            self?.lockQueue.async {
//                self?.recordData()
//            }
//        }
//    }
//
//    func recordData() {
//        let newFrame = collectFrame()
//        let totalArtifacts = numberOfArtifactsRemoved
//        sendToWatch(frame: newFrame, state: isRecording ? .recording : .stop)
//
//        DispatchQueue.main.async { [weak self] in
//            self?.recorder.record(frame: newFrame)
//            self?.recorder.numberOfArtifactsRemoved = totalArtifacts
//        }
//    }
//
//    func sendToWatch(frame: Workout.DataFrame, state: RecordingState) {
//        #if os(iOS)
//        let message = WatchMessage(frame: frame, recordingState: state)
//        if
//            watchSession.isReachable,
//            let messageData = try? encoder.encode(message)
//        {
//            watchSession.sendMessageData(messageData, replyHandler: nil, errorHandler: nil)
//        }
//        #endif
//    }
//
//    func update(for settings: UserSettings) {
//        dfaAlphaStream.artifactCorrectionThreshold = settings.artifactCorrectionThreshold
//        dfaAlphaStream.windowDuration = settings.dfaWindow
//        baselineWorkoutID = settings.baselineWorkoutID
//
//        if let ftp = settings.ftp {
//            lsctDetector = LSCTStreamDetector(
//                stages: .defaultWith(ftp: Double(ftp)),
//                threshold: 0.4
//            )
//        } else {
//            lsctDetector = nil
//        }
//    }
//
//    func register(powerHandler: PowerMeterHandler) {
//        powerListner = powerHandler.powerPublisher
//            .sink(receiveValue: { [weak self] power in
//                self?.newPower = power
//                self?.lsctDetector?.add(power: Double(power))
//                self?.checkForNewLSCTDetection()
//            })
//
//        cadenceListner = powerHandler.cadencePublisher
//            .compactMap { $0 }
//            .assign(to: \.newCadence, on: self)
//
//        powerBalanceListner = powerHandler.pedalPowerBalancePublisher
//            .compactMap { $0 }
//            .assign(to: \.newPowerBalance, on: self)
//    }
//
//    func register(heartBeatHandler: HeartBeatHandler) {
//        heartBeatListner = heartBeatHandler.heartRatePublisher
//            .sink(receiveValue: { [weak self] bpm in
//                self?.newHeartRate = bpm
//            })
//        rrIntervallListner = heartBeatHandler.rrIntervalPublisher
//            .receive(on: lockQueue)
//            .sink(receiveValue: { [weak self] rrInterval in
//                self?.newRRIntervals.append(rrInterval)
//                self?.dfaAlphaStream.add(value: rrInterval)
//            })
//    }
//
//    func resetValues() {
//        newHeartRate = nil
//        newRRIntervals = []
//        newPower = nil
//    }
//
//    func collectFrame() -> Workout.DataFrame {
//        let dfaValue = try? dfaAlphaStream.compute().beta
//        timestamp = timestamp + (isRecording ? 1 : 0)
//        let newFrame = Workout.DataFrame(
//            timestamp: timestamp,
//            heartRate: newHeartRate ?? prevValues.heartRate,
//            power: newPower ?? prevValues.power,
//            cadence: newCadence ?? prevValues.cadence,
//            dfaAlpha1: dfaValue ?? prevValues.dfaAlpha1,
//            rrIntervals: newRRIntervals.isEmpty ? nil : newRRIntervals,
//            ratingOfPervicedEffort: nil,
//            powerBalance: newPowerBalance ?? prevValues.powerBalance
//        )
//        resetValues()
//        prevValues = newFrame
//        return newFrame
//    }
//
//    func startRecording() {
//        isRecording = true
//    }
//
//    func pauseRecording() {
//        isRecording = false
//    }
//
//    func stopRecording() {
//        pauseRecording()
//        timestamp = 0
//        prevValues = .init(timestamp: 0)
//        sendToWatch(frame: .init(timestamp: 0), state: .stop)
//        resetValues()
//    }
//
//    private func checkForNewLSCTDetection() {
//        if
//            lsctDetector?.isBelowThreshold == true,
//            let meanSquareError = lsctDetector?.meanSquareError
//        {
//            if
//                let prevDetection = lsctDetection,
//                meanSquareError < prevDetection.meanSquareError
//            {
//                lsctDetection = .init(
//                    frameWorkout: timestamp,
//                    meanSquareError: meanSquareError
//                )
//            } else if lsctDetection == nil {
//                lsctDetection = .init(
//                    frameWorkout: timestamp,
//                    meanSquareError: meanSquareError
//                )
//            }
//        }
//    }
//}

///// Records and generates a workout
//struct ActivityRecorder {
//
//    var workoutID: UUID
//
//    var startedAt: Date
//
//    var recordedData: [Workout.DataFrame] = []
//
//    var currentFrame: Workout.DataFrame = .init(timestamp: 0)
//
//    var totalNumberOfRRIntervals = 0
//
//    var numberOfArtifactsRemoved: Int = 0
//
//    var artifactsPercentage: Double {
//        guard totalNumberOfRRIntervals != 0 else { return 0 }
//        return Double(numberOfArtifactsRemoved) / Double(totalNumberOfRRIntervals)
//    }
//
//    var workout: Workout {
//        .init(
//            id: workoutID,
//            startedAt: startedAt,
//            values: recordedData,
//            powerCurve: nil
//        )
//    }
//
//    mutating func record(frame: Workout.DataFrame) {
//        if let rrIntervals = frame.rrIntervals {
//            totalNumberOfRRIntervals += rrIntervals.count
//        }
//        if frame.timestamp > currentFrame.timestamp {
//            recordedData.append(currentFrame)
//        }
//        currentFrame = frame
//    }
//}
