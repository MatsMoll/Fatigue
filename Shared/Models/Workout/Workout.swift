//
//  Workout.swift
//  Fatigue
//
//  Created by Mats Mollestad on 03/06/2021.
//

import Foundation
import Combine

class Workout: Identifiable, Codable {
    
    struct Summary: Codable {
        let power: PowerSummary?
        let heartRate: HeartRateSummary?
        let cadence: CadenceSummary?
    }
    
    struct PowerSummary: Codable {
        let average: Int
        let normalized: Int
        let powerBalance: PowerBalance?
        
        let max: Int
    }
    
    struct HeartRateSummary: Codable {
        let average: Int
        let max: Int
        
        let dfaAlpha: DFAAlphaSummary?
    }
    
    struct DFAAlphaSummary: Codable {
        let average: Double
        let min: Double
    }
    
    struct CadenceSummary: Codable {
        let average: Int
        let max: Int
    }
    
    enum UpdateError: Error {
        case invalidValueLength
    }
    
    
    let id: UUID
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
    
    internal init(id: UUID, startedAt: Date, values: [WorkoutFrame], laps: [Int]) {
        self.id = id
        self.startedAt = startedAt
        self.frames = values
        self.laps = laps
    }
}

struct GenericError: Error {
    let reason: String
    
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
