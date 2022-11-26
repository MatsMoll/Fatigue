//
//  Workout.swift
//  Fatigue
//
//  Created by Mats Mollestad on 03/06/2021.
//

import Foundation
import Combine

public class Workout: Identifiable, Codable {
    
    public struct Summary: Codable, Equatable {
        let power: PowerSummary?
        let heartRate: HeartRateSummary?
        let cadence: CadenceSummary?
    }
    
    public struct PowerSummary: Codable, Equatable {
        let average: Int
        let normalized: Int
        let powerBalance: PowerBalance?
        
        let max: Int
    }
    
    public struct HeartRateSummary: Codable, Equatable {
        let average: Int
        let max: Int
        
        let dfaAlpha: DFAAlphaSummary?
    }
    
    public struct DFAAlphaSummary: Codable, Equatable {
        let average: Double
        let min: Double
    }
    
    public struct CadenceSummary: Codable, Equatable {
        let average: Int
        let max: Int
    }
    
    enum UpdateError: Error {
        case invalidValueLength
    }
    
    
    public let id: UUID
    let startedAt: Date
    
    var frames: [WorkoutFrame]
    private (set) var laps: [Int]
    
    var summary: Summary?
    
    var powerSummary: PowerSummary? { summary?.power }
    var heartRateSummary: HeartRateSummary? { summary?.heartRate }
    var cadenceSummary: CadenceSummary? { summary?.cadence }
    
    var hasPower: Bool { powerSummary != nil }
    var hasHeartRate: Bool { heartRateSummary != nil }
    var hasCadence: Bool { cadenceSummary != nil }
    
    var powerCurve: MeanMaximalPower.Curve?
    var lsctDetection: LSCTDetector.Detection?
    
    var elapsedTime: Int { frames.last?.timestamp ?? 0 }
    
    public init(id: UUID, startedAt: Date, values: [WorkoutFrame], laps: [Int]) {
        self.id = id
        self.startedAt = startedAt
        self.frames = values
        self.laps = laps
    }
}

struct GenericError: Error, LocalizedError {
    let reason: String
    
    var errorDescription: String? { reason }
    var failureReason: String? { reason }
    
    init(reason: String) {
        self.reason = reason
    }
}

extension Workout {
    var overview: Workout.Overview {
        return Workout.Overview(
            id: id,
            duration: elapsedTime,
            startedAt: startedAt
        )
    }
}

extension Workout.Summary {
    static var preview: Workout.Summary {
        Workout.Summary(
            power: Workout.PowerSummary(
                average: 300,
                normalized: 321,
                powerBalance: PowerBalance(percentage: 0.54, reference: .left),
                max: 469
            ),
            heartRate: Workout.HeartRateSummary(
                average: 183,
                max: 188,
                dfaAlpha: Workout.DFAAlphaSummary(average: 0.5432, min: 0.444)
            ),
            cadence: Workout.CadenceSummary(average: 92, max: 103)
        )
    }
}
