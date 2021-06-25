//
//  DFAComputation.swift
//  Fatigue
//
//  Created by Mats Mollestad on 15/06/2021.
//

import Foundation
import Combine

class DFAComputation: WorkoutComputation {
    
    var id: String { "DFAComputation\(workout.id.uuidString)" }
    
    var state: WorkoutComputationState = .idle
    
    let workout: Workout
    
    init(workout: Workout) {
        self.workout = workout
    }
    
    var onResultPublisher: AnyPublisher<[Double], Never> { onResultSubject.eraseToAnyPublisher() }
    var onProgressPublisher: AnyPublisher<Double, Never> { onProgressSubject.eraseToAnyPublisher() }
    
    private let onResultSubject = PassthroughSubject<[Double], Never>()
    private let onProgressSubject = PassthroughSubject<Double, Never>()
    
    func startComputation(with settings: UserSettings) {
        
        guard workout.heartRateSummary != nil, state == .idle else { return }
        
        state = .computing
        let numberOfValues = Double(workout.values.count)
        let dfaAlphaModel = DFAStreamModel(artifactCorrectionThreshold: settings.artifactCorrectionThreshold)
        var lastProgress = 0.0
        
        var dfaValues = [Double].init(repeating: 0, count: workout.values.count)
        
        for (index, frame) in workout.values.enumerated() {
            var dfaAlpha1: Double?
            
            if let rrIntervals = frame.rrIntervals {
                for rrValue in rrIntervals {
                    dfaAlphaModel.add(value: rrValue)
                }
                dfaAlpha1 = try? dfaAlphaModel.compute().beta
            }
            
            dfaValues[index] = dfaAlpha1 ?? 0
            
            let newProgress = Double(index + 1) / numberOfValues
            if newProgress - lastProgress > 0.01 {
                lastProgress = newProgress
                onProgressSubject.send(newProgress)
            }
        }
        
        onResultSubject.send(dfaValues)
        state = .computed
    }
}
