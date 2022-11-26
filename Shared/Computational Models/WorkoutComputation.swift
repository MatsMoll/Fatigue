//
//  WorkoutComputation.swift
//  Fatigue
//
//  Created by Mats Mollestad on 24/06/2021.
//

import Foundation
import Combine

// Distribute tasks over multiple Threads
// Define input, and output / how to store result
// Easy define task logic

protocol ComputationalTask {
    
    associatedtype Output
    
    var id: String { get }
    var workout: Workout { get }
    
    var onProgress: AnyPublisher<Double, Never>? { get }
    
    func compute(with settings: UserSettings) async throws -> Output
}

extension ComputationalTask {
    var id: String { "\(String(describing: Self.self))-\(workout.id)" }
    var onProgress: AnyPublisher<Double, Never>? { nil }
}

struct SummaryWorkoutComputation: ComputationalTask {
    
    let workout: Workout
    
    func compute(with settings: UserSettings) async throws -> Workout.Summary {
        
        var power: [Int] = []
        var powerBalance: [PowerBalance] = []
        var heartRate: [Int] = []
        var cadence: [Int] = []
        var dfaAlpha: [Double] = []
        
        for frame in workout.frames {
            if let powerValue = frame.power {
                power.append(powerValue.value)
            }
            if let balance = frame.power?.balance {
                powerBalance.append(balance)
            }
            if let heartRateValue = frame.heartRate {
                heartRate.append(heartRateValue.value)
                
                if let dfaValue = heartRateValue.dfaAlpha1 {
                    dfaAlpha.append(dfaValue)
                }
            }
            if let cadenceValue = frame.cadence {
                cadence.append(cadenceValue.value)
            }
        }
        
        var powerSummary: Workout.PowerSummary?
        var heartRateSummary: Workout.HeartRateSummary?
        var cadenceSummary: Workout.CadenceSummary?
        var dfaSummary: Workout.DFAAlphaSummary?
        
        if !power.isEmpty {
            var balance: PowerBalance?
            if !powerBalance.isEmpty {
                balance = PowerBalance(
                    percentage: powerBalance.map(\.percentage).mean(),
                    reference: powerBalance.first!.reference
                )
            }
            
            let average = power.meanWithoutZeros()
            if average.isNormal {
                powerSummary = Workout.PowerSummary(
                    average: Int(average),
                    normalized: NormalizedPowerModel.compute(values: power.map(Double.init)),
                    powerBalance: balance,
                    max: power.max() ?? 0
                )
            }
        }
        if !dfaAlpha.isEmpty {
            dfaSummary = .init(
                average: dfaAlpha.mean(),
                min: dfaAlpha.min() ?? 0
            )
        }
        if !heartRate.isEmpty {
            heartRateSummary = Workout.HeartRateSummary(
                average: Int(heartRate.mean()),
                max: heartRate.max() ?? 0,
                dfaAlpha: dfaSummary
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

