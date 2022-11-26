//
//  Workout+DataFrame.swift
//  Workout+DataFrame
//
//  Created by Mats Mollestad on 04/09/2021.
//

import Foundation

public struct WorkoutFrame: Codable {
    
    public let timestamp: Int
    public let power: Power?
    public let heartRate: HeartRate?
    public let cadence: Cadence?
    
    public init(timestamp: Int, power: WorkoutFrame.Power?, heartRate: WorkoutFrame.HeartRate?, cadence: WorkoutFrame.Cadence?) {
        self.timestamp = timestamp
        self.power = power
        self.heartRate = heartRate
        self.cadence = cadence
    }
    
    public func fill(with frame: WorkoutFrame) -> WorkoutFrame {
        return .init(
            timestamp: timestamp,
            power: power ?? frame.power,
            heartRate: heartRate ?? frame.heartRate,
            cadence: cadence ?? frame.cadence
        )
    }
    
    public func update(with frame: WorkoutFrame) -> WorkoutFrame {
        return .init(
            timestamp: timestamp,
            power: frame.power ?? power,
            heartRate: frame.heartRate ?? heartRate,
            cadence: frame.cadence ?? cadence
        )
    }
}

extension Int {
    var asDouble: Double { Double(self) }
}

extension WorkoutFrame {
    /// Is optional in order to make the CSV generation easy
    var optionalTimestamp: Int? { timestamp }
}

extension WorkoutFrame {
    public struct Power: Codable {
        
        public let value: Int
        public let balance: PowerBalance?
        
        public init(value: Int, balance: PowerBalance?) {
            self.value = value
            self.balance = balance
        }
    }
    
    public struct HeartRate: Codable {
        
        public let value: Int
        public let rrIntervals: [Double]
        public let dfaAlpha1: Double?
        
        public init(value: Int, rrIntervals: [Double], dfaAlpha1: Double?) {
            self.value = value
            self.rrIntervals = rrIntervals
            self.dfaAlpha1 = dfaAlpha1
        }
    }
    
    public struct Cadence: Codable {
        
        public let value: Int
        
        public init(value: Int) {
            self.value = value
        }
    }
    
    struct Mutable {
        let timestamp: Int
        var power: Power?
        var heartRate: HeartRate?
        var cadence: Cadence?
        
        var frame: WorkoutFrame {
            .init(
                timestamp: timestamp,
                power: power,
                heartRate: heartRate,
                cadence: cadence
            )
        }
    }
}
