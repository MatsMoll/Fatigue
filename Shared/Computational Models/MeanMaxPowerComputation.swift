//
//  MeanMaxPowerComputation.swift
//  Fatigue
//
//  Created by Mats Mollestad on 24/06/2021.
//

import Foundation
import Combine

class MeanMaximumPowerComputation: ComputationalTask {
    
    var id: String { "MeanMaximumPower\(workout.id.uuidString)" }
    
    let workout: Workout
    
    var onProgress: AnyPublisher<Double, Never> { onProgressSubject.eraseToAnyPublisher() }
    var onResult: AnyPublisher<MeanMaximalPower.Curve, Never> { onResultSubject.eraseToAnyPublisher() }
    
    private let onProgressSubject = PassthroughSubject<Double, Never>()
    private var onResultSubject = PassthroughSubject<MeanMaximalPower.Curve, Never>()
    private let onCompleteSubject = PassthroughSubject<Void, Never>()
    
    internal init(workout: Workout) {
        self.workout = workout
    }
    
    func compute(with settings: UserSettings) async throws -> MeanMaximalPower.Curve {
        
        let powerData = workout.frames.compactMap({ frame -> Double? in
            guard let power = frame.power?.value else { return nil }
            return Double(power)
        })
        guard !powerData.isEmpty else {
            throw GenericError(reason: "Missing power data")
        }
        let curve = MeanMaximalPower().generate(powers: powerData) { progress in
            onProgressSubject.send(progress)
        }
        
        return curve
    }
}
