//
//  Workout+DataFrame.swift
//  Workout+DataFrame
//
//  Created by Mats Mollestad on 04/09/2021.
//

import Foundation

struct WorkoutFrame: Codable {
    let timestamp: Int
    let power: Power?
    let heartRate: HeartRate?
    let cadence: Cadence?
}

extension WorkoutFrame {
    /// Is optional in order to make the CSV generation easy
    var optionalTimestamp: Int? { timestamp }
}

extension WorkoutFrame {
    struct Power: Codable {
        let value: Int
        let balance: PowerBalance?
    }
    
    struct HeartRate: Codable {
        let value: Int
        let rrIntervals: [Double]
        let dfaAlpha1: Double?
    }
    
    struct Cadence: Codable {
        let value: Int
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
