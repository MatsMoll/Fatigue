//
//  LSCTDetector.swift
//  Fatigue
//
//  Created by Mats Mollestad on 04/06/2021.
//

import Foundation
import Combine

extension Array where Element == LSCTStage {
    
    static func defaultWith(ftp: Double) -> [LSCTStage] {
        return [
            LSCTStage(duration: 6 * 60, targetPower: ftp * 0.7),
            LSCTStage(duration: 6 * 60, targetPower: ftp * 0.9),
            LSCTStage(duration: 3 * 60, targetPower: ftp),
            LSCTStage(duration: 60, targetPower: 0),
        ]
    }
}

struct LSCTDetectorError: Error {
    
    let reason: String
    
    static let workoutIsToShort = LSCTDetectorError(reason: "Workout is shorter then the LSCT Test")
}

class LSCTDetector {
    
    struct Detection: Codable, Equatable {
        let frameWorkout: Int
        let meanSquareError: Double
    }
    
    let dataFrames: [Workout.DataFrame]
    
    let stages: [LSCTStage]
    
    init(dataFrames: [Workout.DataFrame], stages: [LSCTStage]) {
        self.dataFrames = dataFrames
        self.stages = stages
    }
    
    /// Detects if a test exists in a workout
    /// - Returns:
    func detectTest() throws -> Detection {
        
        let totalDuration = stages.reduce(0, { $0 + $1.duration })
        
        var detection = Detection(
            frameWorkout: 0,
            meanSquareError: .infinity
        )
        
        let streamDetector = LSCTStreamDetector(stages: stages, threshold: 0.4)
        
        for (index, value) in dataFrames.enumerated() {
            streamDetector.add(power: Double(value.power ?? 0))
            
            if
                index >= totalDuration,
                detection.meanSquareError > streamDetector.meanSquareError
            {
                detection = Detection(
                    frameWorkout: index - totalDuration,
                    meanSquareError: streamDetector.meanSquareError
                )
            }
        }
        
        return detection
    }
}
