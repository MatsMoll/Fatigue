//
//  MeanMaximalPower.swift
//  Fatigue
//
//  Created by Mats Mollestad on 02/06/2021.
//

import Foundation
import Combine

struct MeanMaximalPower {
    
    struct Curve: Codable {
        
        /// The max means at a given index / second
        let means: [Int]
        
        func maxMean(at second: Int) throws -> Int {
            guard 0..<means.count ~= second else {
                return .zero
            }
            return means[second]
        }
    }
    
    func generate(powers: [Double], progress: (Double) -> Void) -> Curve {
        
        var maxMeans = Array<Double>(repeating: 0.0, count: powers.count)
        var means = Array<Double>(repeating: 0.0, count: powers.count)
        
        let numberOfComputations = Double(powers.count * powers.count) / 2
        var lastProgress: Double = 0
        for (index, power) in powers.enumerated() {
            
            for i in 0..<index {
                let j = index - i
                let averagePower = (means[j - 1] * Double(j) + power) / Double(j + 1)
                means[j] = averagePower
                
                if averagePower > maxMeans[j] {
                    maxMeans[j] = averagePower
                }
                
                let newProgress = Double(index * index / 2 + i) / numberOfComputations
                if newProgress - lastProgress > 0.01 {
                    lastProgress = newProgress
                    progress(newProgress)
                }
            }
            
            if power > maxMeans[0] {
                maxMeans[0] = power
            }
            means[0] = power
        }
        
        return Curve(means: maxMeans.map { Int($0) })
    }
}

class MeanMaximumPowerComputation: WorkoutComputation {
    
    var id: String { "MeanMaximumPower\(workout.id.uuidString)" }
    
    let workout: Workout
    var state: WorkoutComputationState { .idle }
    
    var onProgress: AnyPublisher<Double, Never> { onProgressSubject.eraseToAnyPublisher() }
    var onResult: AnyPublisher<MeanMaximalPower.Curve, Never> { onResultSubject.eraseToAnyPublisher() }
    
    private let onProgressSubject = PassthroughSubject<Double, Never>()
    private var onResultSubject = PassthroughSubject<MeanMaximalPower.Curve, Never>()
    private let onCompleteSubject = PassthroughSubject<Void, Never>()
    
    internal init(workout: Workout) {
        self.workout = workout
    }
    
    func startComputation(with settings: UserSettings) -> AnyPublisher<Void, Never> {
        
        defer { onCompleteSubject.send(()) }
        
        if workout.powerCurve != nil {
            return onCompleteSubject.eraseToAnyPublisher()
        }
        
        let powerData = workout.values.compactMap({ frame -> Double? in
            guard let power = frame.power else { return nil }
            return Double(power)
        })
        let curve = MeanMaximalPower().generate(powers: powerData) { progress in
            onProgressSubject.send(progress)
        }
        
        onResultSubject.send(curve)
        
        return onCompleteSubject.eraseToAnyPublisher()
    }
}
