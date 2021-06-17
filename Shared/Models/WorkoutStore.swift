//
//  WorkoutStore.swift
//  Fatigue
//
//  Created by Mats Mollestad on 29/05/2021.
//

import Foundation
import FitDataProtocol
import OSLog

struct GenericError: Error {
    let reason: String
    
    init(reason: String) {
        self.reason = reason
    }
}


struct WorkoutStore {
    
    let userDefaults: UserDefaults
    
    var selectedWorkoutId: UUID?
    
    var hasLoadedFromFile: Bool = false
    
    private (set) var workouts: [Workout] = []
    
    let encoder = PropertyListEncoder()
    let decoder = PropertyListDecoder()
    
    let logger = Logger(subsystem: "fatigue.workout-store", category: "workout-store")
    
    func saveWorkouts() throws {
        do {
            let data = try encoder.encode(workouts)
            userDefaults.setValue(data, forKey: "workouts")
            logger.debug("Saved Workouts")
        } catch {
            logger.debug("Error saving: \(error.localizedDescription)")
        }
    }
    
    mutating func loadWorkouts() {
        do {
            guard let data = userDefaults.data(forKey: "workouts") else { return }
            var loadedWorkouts = try decoder.decode([Workout].self, from: data)
            for index in 0..<loadedWorkouts.count {
                loadedWorkouts[index].calculateSummary()
            }
            workouts = loadedWorkouts
            hasLoadedFromFile = true
            logger.debug("Loaded Workouts")
        } catch {
            logger.debug("Error Loading: \(error.localizedDescription)")
        }
    }
    
    mutating func deleteWorkout(with id: UUID) {
        workouts.removeAll(where: { $0.id == id })
        try? saveWorkouts()
    }
    
    mutating func deleteWorkout(indexSet: IndexSet) {
        workouts.remove(atOffsets: indexSet)
        try? saveWorkouts()
    }
    
    mutating func add(_ workout: Workout) {
        if !hasLoadedFromFile {
            loadWorkouts()
        }
        workouts.append(workout)
        try? saveWorkouts()
    }
    
    mutating func update(dfa values: [Double], for id: UUID) {
        guard let index = workouts.firstIndex(where: { $0.id == id }) else { return }
        try? workouts[index].update(dfaAlpha: values)
        try? saveWorkouts()
    }
    
    mutating func update(_ curve: MeanMaximalPower.Curve, for id: UUID) {
        guard let index = workouts.firstIndex(where: { $0.id == id }) else { return }
        workouts[index].powerCurve = curve
        try? saveWorkouts()
    }
    
    func workout(with id: UUID) -> Workout? {
        workouts.first(where: { $0.id == id })
    }
}
