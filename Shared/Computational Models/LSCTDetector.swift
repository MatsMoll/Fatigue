//
//  LSCTDetector.swift
//  Fatigue
//
//  Created by Mats Mollestad on 04/06/2021.
//

import Foundation
import Combine

struct LSCTStage {
    
    /// The number of data frames / seconds in a stage
    let duration: Int
    
    /// The target power
    let targetPower: Double
}

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
    
    struct Detection {
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
        let endIndex = dataFrames.count - totalDuration
        guard endIndex > 0 else {
            throw LSCTDetectorError.workoutIsToShort
        }
        
        var detection = Detection(
            frameWorkout: 0,
            meanSquareError: .infinity
        )
        
        // Min power target or 1
        let minTargetPower = stages
            .filter({ $0.targetPower != 0 })
            .min(by: { $0.targetPower < $1.targetPower })?.targetPower ?? 1
        
        for index in 0..<endIndex {
            
            var meanSquareError: Double = 0.0
            var stageOffset = 0
            
            for stage in stages {
                for j in 0..<stage.duration {
                    let power = Double(dataFrames[index + stageOffset + j].power ?? 0)
                    if stage.targetPower == 0 {
                        let fractionalDiff = pow(abs(power / minTargetPower) + 1, 2)
                        meanSquareError += fractionalDiff / Double(totalDuration)
                    } else {
                        let fractionalDiff = pow(abs((power - stage.targetPower) / stage.targetPower) + 1, 2)
                        meanSquareError += fractionalDiff / Double(totalDuration)
                    }
                }
                
                stageOffset += stage.duration
            }
            
            meanSquareError -= 1
            if detection.meanSquareError > meanSquareError {
                detection = Detection(
                    frameWorkout: index,
                    meanSquareError: meanSquareError
                )
            }
        }
        
        return detection
    }
}
