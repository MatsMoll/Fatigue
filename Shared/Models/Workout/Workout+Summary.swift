//
//  Workout+Summary.swift
//  Workout+Summary
//
//  Created by Mats Mollestad on 04/09/2021.
//

import Foundation

extension Workout {
    /// A overview for a workout
    /// This can be used in order to improve loading time of workouts In a list.
    struct Overview: Identifiable, Codable {
        let id: UUID
        let duration: Int
        let startedAt: Date
    }
}
