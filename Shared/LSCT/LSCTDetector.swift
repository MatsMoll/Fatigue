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
        #if DEBUG
        return [
            LSCTStage(duration: 10, targetPower: ftp * 0.7),
            LSCTStage(duration: 10, targetPower: ftp * 0.9),
            LSCTStage(duration: 5, targetPower: ftp),
            LSCTStage(duration: 10, targetPower: 0),
        ]
        #else
        return [
            LSCTStage(duration: 6 * 60, targetPower: ftp * 0.7),
            LSCTStage(duration: 6 * 60, targetPower: ftp * 0.9),
            LSCTStage(duration: 3 * 60, targetPower: ftp),
            LSCTStage(duration: 60, targetPower: 0),
        ]
        #endif
    }
}

struct LSCTDetectorError: Error {
    
    let reason: String
    
    static let workoutIsToShort = LSCTDetectorError(reason: "Workout is shorter then the LSCT Test")
}

public class LSCTDetector {
    
    public struct Detection: Codable, Equatable {
        public let frameWorkout: Int
        public let meanSquareError: Double
    }
    
    let dataFrames: [WorkoutFrame]
    
    let stages: [LSCTStage]
    
    init(dataFrames: [WorkoutFrame], stages: [LSCTStage]) {
        self.dataFrames = dataFrames
        self.stages = stages
    }
    
    /// Detects if a test exists in a workout
    /// - Returns:
    func detectTest() throws -> Detection {
        
        let streamDetector = LSCTStreamDetector(stages: stages, threshold: 0.4)
        
        for value in dataFrames {
            streamDetector.add(power: Double(value.power?.value ?? 0))
        }
        
        guard let detection = streamDetector.detection else {
            throw GenericError(reason: "Not able to find match for some reason")
        }
        return detection
    }
}
