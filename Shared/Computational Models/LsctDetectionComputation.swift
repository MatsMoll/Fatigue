//
//  LsctDetectionComputation.swift
//  Fatigue
//
//  Created by Mats Mollestad on 17/10/2021.
//

import Foundation

struct LsctDetectionComputation: ComputationalTask {
    
    let workout: Workout
    
    let storeIn: WritableKeyPath<Workout, LSCTDetector.Detection?> = \.lsctDetection
    
    func compute(with settings: UserSettings) async throws -> LSCTDetector.Detection {
        
        guard let ftp = settings.ftp else {
            throw GenericError(reason: "Can not compute LSCT as no FTP has been set")
        }
        let detector = LSCTDetector(
            dataFrames: workout.frames,
            stages: .defaultWith(ftp: Double(ftp))
        )
        
        return try detector.detectTest()
    }
}

