//
//  LSCTRestultComputation.swift
//  Fatigue
//
//  Created by Mats Mollestad on 14/06/2021.
//

import Foundation
import Combine

class LSCTResultComputation: ComputationalTask {

    let workout: Workout
    let baseline: Workout

    init(workout: Workout, baseline: Workout) {
        self.workout = workout
        self.baseline = baseline
    }

    func compute(with settings: UserSettings) async throws -> LSCTResult {

        let stages: [LSCTStage] = .defaultWith(ftp: Double(settings.ftp ?? 280))
        let mainDetector = LSCTDetector(dataFrames: workout.frames, stages: stages)
        let baselineDetector = LSCTDetector(dataFrames: baseline.frames, stages: stages)

        let durations = stages.filter{ $0.targetPower != 0 }.map(\.duration)
        let hrrDuration = stages.first(where: { $0.targetPower == 0 })?.duration ?? 60

        do {
            let mainDetection = try mainDetector.detectTest()
            let baselineDetection = try baselineDetector.detectTest()

            let mainRun = try await workout.lsctRun(startingAt: mainDetection.frameWorkout, stageDurations: durations, hrrDuration: hrrDuration)
            let baselineRun = try await baseline.lsctRun(startingAt: baselineDetection.frameWorkout, stageDurations: durations, hrrDuration: hrrDuration)

            return try mainRun.compare(with: baselineRun)
        } catch {
            throw error
        }
    }
}

class LSCTResultStreamComputation {

    let workout: Workout
    let baseline: Workout
    
    private(set) var detector: LSCTStreamDetector
    private(set) var baselineRun: LSCTRun?
    private(set) var prevResult: LSCTResult?
    
    var shouldComputeNewResult: Bool {
        guard let detection = detector.detection else { return true }
        return detection.frameWorkout != prevResult?.runIdentifer.startingAt
    }
    
    let stages: [LSCTStage]
    let durations: [Int]
    let hrrDuration: Int

    init(workout: Workout, baseline: Workout, ftp: Int) {
        self.workout = workout
        self.baseline = baseline
        let stages: [LSCTStage] = .defaultWith(ftp: Double(ftp))
        self.stages = stages
        #if DEBUG
        self.detector = LSCTStreamDetector(stages: stages, threshold: 1)
        #else
        self.detector = LSCTStreamDetector(stages: stages, threshold: 0.3)
        #endif
        self.durations = stages.filter{ $0.targetPower != 0 }.map(\.duration)
        self.hrrDuration = stages.first(where: { $0.targetPower == 0 })?.duration ?? 60
    }
    
    func reset() {
        detector = LSCTStreamDetector(stages: detector.stages, threshold: detector.threshold)
        workout.frames = []
        prevResult = nil
    }
    
    func updateDetector() {
        let missingValueCount = workout.frames.count - detector.totalValueCount
        for _ in 0..<missingValueCount {
            let frame = workout.frames[detector.totalValueCount]
            detector.add(power: Double(frame.power?.value ?? 0))
        }
    }
    
    func compute() async throws -> LSCTResult {
        updateDetector()
        guard
            let mainDetection = detector.detection
        else {
            throw GenericError(reason: "Did not find any relevent candicates for LSCT test")
        }
        guard shouldComputeNewResult else { return prevResult! }
        do {
            let compareRun: LSCTRun!
            if let baselineRun = baselineRun {
                compareRun = baselineRun
            } else {
                let baselineDetector = LSCTDetector(dataFrames: baseline.frames, stages: stages)
                let baselineDetection = try baselineDetector.detectTest()
                compareRun = try await baseline.lsctRun(startingAt: baselineDetection.frameWorkout, stageDurations: durations, hrrDuration: hrrDuration)
                baselineRun = compareRun
            }

            let mainRun = try await workout.lsctRun(startingAt: mainDetection.frameWorkout, stageDurations: durations, hrrDuration: hrrDuration)
            let result = try mainRun.compare(with: compareRun)
            prevResult = result
            return result
        } catch {
            throw error
        }
    }
}
