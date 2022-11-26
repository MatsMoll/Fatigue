//
//  Workout+Old.swift
//  Fatigue
//
//  Created by Mats Mollestad on 09/12/2021.
//

import Foundation


extension Workout {
    
    struct Old: Identifiable, Codable {
        
        struct PowerSummary: Codable {
            let average: Int
            let normalized: Int
            let powerBalance: PowerBalance?
        }
        
        struct HeartRateSummary: Codable {
            let average: Int
        }
        
        struct DFAAlphaSummary: Codable {
            let average: Double
        }
        
        struct CadenceSummary: Codable {
            let average: Int
        }
        
        enum UpdateError: Error {
            case invalidValueLength
        }
        
        struct DataFrame: Codable {
            internal init(
                timestamp: Int,
                heartRate: Int? = nil,
                power: Int? = nil,
                cadence: Int? = nil,
                dfaAlpha1: Double? = nil,
                rrIntervals: [Double]? = nil,
                ratingOfPervicedEffort: Int? = nil,
                powerBalance: PowerBalance? = nil
            ) {
                self.timestamp = timestamp
                self.heartRate = heartRate
                self.power = power
                self.cadence = cadence
                self.dfaAlpha1 = dfaAlpha1
                self.rrIntervals = rrIntervals
                self.ratingOfPervicedEffort = ratingOfPervicedEffort
                self.powerBalance = powerBalance
            }
            
            let timestamp: Int
            let heartRate: Int?
            let power: Int?
            let cadence: Int?
            let dfaAlpha1: Double?
            let rrIntervals: [Double]?
            let ratingOfPervicedEffort: Int?
            let powerBalance: PowerBalance?
        }
        
        let id: UUID
        let startedAt: Date
        
        private (set) var values: [DataFrame]
        
        var powerCurve: MeanMaximalPower.Curve?
        
        var lsctDetection: LSCTDetector.Detection?
        
        var powerSummary: PowerSummary?
        var heartRateSummary: HeartRateSummary?
        var dfaAlphaSummary: DFAAlphaSummary?
        var cadenceSummary: CadenceSummary?
        
        var elapsedTime: Int {
            values.last?.timestamp ?? 0
        }
        
        var hasDFAValues: Bool { dfaAlphaSummary != nil }
        
        internal init(id: UUID, startedAt: Date, values: [Workout.Old.DataFrame], powerCurve: MeanMaximalPower.Curve?) {
            self.id = id
            self.startedAt = startedAt
            self.values = values
            self.powerCurve = powerCurve
        }
    }
}

extension Workout.Old.DataFrame {
    
//    let timestamp: Int
//    let heartRate: Int?
//    let power: Int?
//    let cadence: Int?
//    let dfaAlpha1: Double?
//    let rrIntervals: [Double]?
//    let ratingOfPervicedEffort: Int?
//    let powerBalance: PowerBalance?
    
    var updated: WorkoutFrame {
        
        return .init(
            timestamp: timestamp,
            power: power.map { WorkoutFrame.Power(value: $0, balance: powerBalance) },
            heartRate: heartRate.map { WorkoutFrame.HeartRate(value: $0, rrIntervals: rrIntervals ?? [], dfaAlpha1: dfaAlpha1) },
            cadence: cadence.map { WorkoutFrame.Cadence(value: $0) }
        )
    }
}

extension Workout.Old {
    
    func updateFormat() async throws -> Workout {
        let workout = Workout(
            id: id,
            startedAt: startedAt,
            values: values.map(\.updated),
            laps: [values.count]
        )
        workout.summary = try await SummaryWorkoutComputation(workout: workout)
            .compute(with: .init())
        return workout
    }
}
