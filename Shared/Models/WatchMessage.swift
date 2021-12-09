//
//  WatchMessage.swift
//  Fatigue
//
//  Created by Mats Mollestad on 24/06/2021.
//

import Foundation

enum RecordingState: Int, Codable, Equatable {
    case pause
    case recording
    case stop
}

struct WatchMessage: Codable {
    
    let frame: WorkoutFrame?
    let recordingState: RecordingState
}
