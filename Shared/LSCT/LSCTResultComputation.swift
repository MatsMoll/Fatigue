//
//  LSCTRestultComputation.swift
//  Fatigue
//
//  Created by Mats Mollestad on 14/06/2021.
//

import Foundation
import Combine

class LSCTResultComputation: WorkoutComputation {
    
    var id: String { "LSCTResult\(workout.id.uuidString)" }
    
    var state: WorkoutComputationState = .idle
    
    let workout: Workout
    let baseline: Workout
    
    init(workout: Workout, baseline: Workout) {
        self.workout = workout
        self.baseline = baseline
    }
    
    var onResultPublisher: AnyPublisher<LSCTResult, Never> { onResultSubject.eraseToAnyPublisher() }
    
    private var onResultSubject = PassthroughSubject<LSCTResult, Never>()
    
    func startComputation(with settings: UserSettings) {
        
        guard workout.powerSummary != nil, state == .idle else { return }
        state = .computing
        
        let stages: [LSCTStage] = .defaultWith(ftp: Double(settings.ftp ?? 280))
        let mainDetector = LSCTDetector(dataFrames: workout.values, stages: stages)
        let baselineDetector = LSCTDetector(dataFrames: baseline.values, stages: stages)
        
        let durations = stages.filter{ $0.targetPower != 0 }.map(\.duration)
        let hrrDuration = stages.first(where: { $0.targetPower == 0 })?.duration ?? 60
        
        do {
            let mainDetection = try mainDetector.detectTest()
            print("Main Detection: \(mainDetection.meanSquareError)")
            let baselineDetection = try baselineDetector.detectTest()
            print("Baseline Detection: \(baselineDetection.meanSquareError)")
            
            let mainRun = try workout.lsctRun(startingAt: mainDetection.frameWorkout, stageDurations: durations, hrrDuration: hrrDuration)
            let baselineRun = try baseline.lsctRun(startingAt: baselineDetection.frameWorkout, stageDurations: durations, hrrDuration: hrrDuration)
            
            let result = try mainRun.compare(with: baselineRun)
            onResultSubject.send(result)
            state = .computed
        } catch {
            print(error)
        }
    }
}
