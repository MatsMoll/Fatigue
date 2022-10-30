//
//  WorkoutComputation.swift
//  Fatigue
//
//  Created by Mats Mollestad on 24/06/2021.
//

import Foundation
import Combine

enum WorkoutComputationState: Int, Equatable {
    case idle
    case computing
    case computed
}

protocol WorkoutComputation {
    
    var id: String { get }
    var state: WorkoutComputationState { get }
    func startComputation(with settings: UserSettings)
}

// Distribute tasks over multiple Threads
// Define input, and output / how to store result
// Easy define task logic

protocol ComputationalTask {
    
    associatedtype Output
    
    var id: String { get }
    var workout: Workout { get }
    var storeIn: WritableKeyPath<Workout, Output?> { get }
    
    var onProgress: AnyPublisher<Double, Never>? { get }
    
    func compute(with settings: UserSettings) throws -> Output
}

extension ComputationalTask {
    var id: String { "\(String(describing: Self.self))-\(workout.id)" }
    var onProgress: AnyPublisher<Double, Never>? { nil }
}

struct SummaryWorkoutComputation: ComputationalTask {
    
    let workout: Workout
    
    let storeIn: WritableKeyPath<Workout, Workout.Summary?> = \.summary
    
    func compute(with settings: UserSettings) throws -> Workout.Summary {
        
        var power: [Int] = []
        var heartRate: [Int] = []
        var cadence: [Int] = []
        
        for frame in workout.frames {
            if let powerValue = frame.power {
                power.append(powerValue.value)
            }
            if let heartRateValue = frame.heartRate {
                heartRate.append(heartRateValue.value)
            }
            if let cadenceValue = frame.cadence {
                cadence.append(cadenceValue.value)
            }
        }
        
        var powerSummary: Workout.PowerSummary?
        var heartRateSummary: Workout.HeartRateSummary?
        var cadenceSummary: Workout.CadenceSummary?
        
        if !power.isEmpty {
            powerSummary = Workout.PowerSummary(
                average: Int(power.meanWithoutZeros()),
                normalized: NormalizedPowerModel.compute(values: power.map(Double.init)),
                powerBalance: nil,
                max: power.max() ?? 0
            )
        }
        if !heartRate.isEmpty {
            heartRateSummary = Workout.HeartRateSummary(
                average: Int(heartRate.mean()),
                max: heartRate.max() ?? 0,
                dfaAlpha: nil
            )
        }
        if !cadence.isEmpty {
            cadenceSummary = Workout.CadenceSummary(
                average: Int(cadence.mean()),
                max: cadence.max() ?? 0
            )
        }
        
        return Workout.Summary(
            power: powerSummary,
            heartRate: heartRateSummary,
            cadence: cadenceSummary
        )
    }
}

//struct MeanMaxComp: ComputationalTask {
//
//    let workout: Workout
//
//    var id: String { "MeanMaxComp-\(workout.id)" }
//    var onProgress: AnyPublisher<Double, Never>? = nil
//
//    var storeIn: KeyPath<Workout, MeanMaximalPower.Curve?> { \Workout.powerCurve }
//
//    func compute(with settings: UserSettings) throws -> Output {
//        let powerValues = workout.frames.compactMap(\.power?.value)
//        MeanMaximalPower().generate(powers: <#T##[Double]#>, progress: <#T##(Double) -> Void#>)
//    }
//}

