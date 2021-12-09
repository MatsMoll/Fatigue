//
//  DFAComputation.swift
//  Fatigue
//
//  Created by Mats Mollestad on 15/06/2021.
//

import Foundation
import Combine

class DFAComputation: ComputationalTask {
    
    var id: String { "DFAComputation\(workout.id.uuidString)" }
    
    let workout: Workout
    
    init(workout: Workout) {
        self.workout = workout
    }
    
    var onProgressPublisher: AnyPublisher<Double, Never> { onProgressSubject.eraseToAnyPublisher() }
    private let onProgressSubject = PassthroughSubject<Double, Never>()
    
    func compute(with settings: UserSettings) async throws -> [Double] {
        
        let numberOfValues = Double(workout.frames.count)
        let dfaAlphaModel = DFAStreamModel(artifactCorrectionThreshold: settings.artifactCorrectionThreshold)
        var lastProgress = 0.0
        
        var dfaValues = [Double].init(repeating: 0, count: workout.frames.count)
        
        for (index, frame) in workout.frames.enumerated() {
            var dfaAlpha1: Double?
            
            if let rrIntervals = frame.heartRate?.rrIntervals {
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
        
        return dfaValues
    }
}
