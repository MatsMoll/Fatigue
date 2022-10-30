//
//  MeanMaxPowerComputation.swift
//  Fatigue
//
//  Created by Mats Mollestad on 24/06/2021.
//

import Foundation
import Combine

class MeanMaximumPowerComputation: WorkoutComputation {
    
    var id: String { "MeanMaximumPower\(workout.id.uuidString)" }
    
    let workout: Workout
    var state: WorkoutComputationState = .idle
    
    var onProgress: AnyPublisher<Double, Never> { onProgressSubject.eraseToAnyPublisher() }
    var onResult: AnyPublisher<MeanMaximalPower.Curve, Never> { onResultSubject.eraseToAnyPublisher() }
    
    private let onProgressSubject = PassthroughSubject<Double, Never>()
    private var onResultSubject = PassthroughSubject<MeanMaximalPower.Curve, Never>()
    private let onCompleteSubject = PassthroughSubject<Void, Never>()
    
    internal init(workout: Workout) {
        self.workout = workout
    }
    
    func startComputation(with settings: UserSettings) {
        
        if workout.powerCurve != nil, state == .idle { return }
        
        state = .computing
        let powerData = workout.frames.compactMap({ frame -> Double? in
            guard let power = frame.power?.value else { return nil }
            return Double(power)
        })
        guard !powerData.isEmpty else {
            state = .computed
            return
        }
        let curve = MeanMaximalPower().generate(powers: powerData) { progress in
            onProgressSubject.send(progress)
        }
        
        onResultSubject.send(curve)
        state = .computed
    }
}
