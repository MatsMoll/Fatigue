//
//  WorkoutComputation.swift
//  Fatigue
//
//  Created by Mats Mollestad on 24/06/2021.
//

import Foundation

enum WorkoutComputationState: Int, Equatable {
    case idle
    case computing
    case computed
}

protocol WorkoutComputation {
    
    var id: String { get }
    var state: WorkoutComputationState { get }
    func startComputation(with settings: UserSettings)
}
