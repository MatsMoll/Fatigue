//
//  Workout.swift
//  Fatigue
//
//  Created by Mats Mollestad on 03/06/2021.
//

import Foundation
import Combine

struct Workout: Identifiable {
    
    struct DataFrame {
        internal init(timestamp: Int, heartRate: Int? = nil, power: Int? = nil, cadence: Int? = nil, dfaAlpha1: Double? = nil, rrIntervals: [Int]? = nil, ratingOfPervicedEffort: Int? = nil) {
            self.timestamp = timestamp
            self.heartRate = heartRate
            self.power = power
            self.cadence = cadence
            self.dfaAlpha1 = dfaAlpha1
            self.rrIntervals = rrIntervals
            self.ratingOfPervicedEffort = ratingOfPervicedEffort
        }
        
        let timestamp: Int
        let heartRate: Int?
        let power: Int?
        let cadence: Int?
        let dfaAlpha1: Double?
        let rrIntervals: [Int]?
        let ratingOfPervicedEffort: Int?
    }
    
    let id: UUID
    let startedAt: Date
    
    var values: [DataFrame]
    
    internal init(id: UUID, startedAt: Date, values: [Workout.DataFrame]) {
        self.id = id
        self.startedAt = startedAt
        self.values = values
        
    }
}
