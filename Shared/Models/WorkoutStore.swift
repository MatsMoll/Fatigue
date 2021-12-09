//
//  WorkoutStore.swift
//  Fatigue
//
//  Created by Mats Mollestad on 29/05/2021.
//

import Foundation
import FitDataProtocol
import OSLog


struct WorkoutStore {
    
    let userDefaults: UserDefaults
    
    var fileManager: FileManager
    
    private let savedFileName: String = "workouts-overview.json"
    private let oldSavedFileName: String = "workouts.json"
    private let lockQueue = DispatchQueue(label: "Fatigue.WorkoutStore", qos: .background)
    
    private var oldWorkoutsURL: URL? {
        do {
            let documentFolder = try fileManager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
            return documentFolder.appendingPathComponent(oldSavedFileName)
        } catch {
            return nil
        }
    }
    
    private var workoutsURL: URL? {
        do {
            let documentFolder = try fileManager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
            return documentFolder.appendingPathComponent(savedFileName)
        } catch {
            return nil
        }
    }
    
    private func workoutUrlWith(id: UUID) -> URL? {
        do {
            let documentFolder = try fileManager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            return documentFolder.appendingPathComponent("workouts").appendingPathComponent("\(id)").appendingPathExtension("json")
        } catch {
            return nil
        }
    }
    
    var selectedWorkoutId: UUID? = nil
    
    var hasLoadedFromFile: Bool = false
    
    var baseline: Workout?
    
    var workouts: [Workout.Overview] = []
    
    let encoder = JSONEncoder()
    let decoder = JSONDecoder()
    
    let isoDateDecoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()
    
    let logger = Logger(subsystem: "fatigue.workout-store", category: "workout-store")
    
    func saveWorkouts() throws {
        lockQueue.async {
            do {
                guard let workoutsFile = workoutsURL else { return }
                let data = try encoder.encode(workouts)
                try data.write(to: workoutsFile)
                logger.debug("Saved Workouts")
            } catch {
                logger.debug("Error saving: \(error.localizedDescription)")
            }
        }
    }
    
    func loadWorkouts() -> [Workout.Overview] {
        do {
            let savedData: Data?
            if
                let workoutsFile = self.workoutsURL,
                fileManager.fileExists(atPath: workoutsFile.path)
            {
                savedData = try Data(contentsOf: workoutsFile)
            } else {
                savedData = userDefaults.data(forKey: "workouts")
            }
            guard let data = savedData else { return [] }
            let loadedWorkouts = try decoder.decode([Workout.Overview].self, from: data)
            logger.debug("Loaded Workouts")
            var loadedWorkoutDates = Set<Date>()
            return loadedWorkouts.filter({ workout in
                if loadedWorkoutDates.contains(workout.startedAt) {
                    return false
                } else {
                    loadedWorkoutDates.insert(workout.startedAt)
                    return true
                }
            }).sorted(by: { $0.startedAt > $1.startedAt })
        } catch {
            logger.debug("Error Loading: \(error.localizedDescription)")
            return []
        }
    }
    
    mutating func deleteWorkout(with id: UUID) throws {
        guard let index = workouts.firstIndex(where: { $0.id == id }) else { return }
        try deleteWorkout(indexSet: .init(integer: index))
    }
    
    mutating func deleteWorkout(indexSet: IndexSet) throws {
        for index in indexSet {
            let workout = workouts[index]
            guard let url = workoutUrlWith(id: workout.id) else { return }
            if fileManager.isDeletableFile(atPath: url.path) {
                try fileManager.removeItem(at: url)
            }
        }
        workouts.remove(atOffsets: indexSet)
        try? saveWorkouts()
    }
    
    mutating func add(_ workout: Workout) {
        if !hasLoadedFromFile {
            self.workouts = loadWorkouts()
            hasLoadedFromFile = true
        }
        do {
            try save(workout: workout)
            workouts.insert(workout.overview, at: 0)
            try saveWorkouts()
        } catch {
            logger.error("Error when saving: \(error.localizedDescription)")
        }
    }
    
    func update(workout: Workout) throws {
        try save(workout: workout)
    }
    
    private func save(workout: Workout) throws {
        logger.info("Saving workout: \(workout.id)")
        let workoutData = try encoder.encode(workout)
        guard let url = workoutUrlWith(id: workout.id) else {
            throw GenericError(reason: "Unable create url from workout")
        }
        if !fileManager.fileExists(atPath: url.deletingLastPathComponent().path) {
            try! fileManager.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true, attributes: nil)
        }
        try workoutData.write(to: url, options: .atomic)
        logger.info("Written workout: \(workout.id)")
    }
    
    func workout(with id: UUID) throws -> Workout? {
        guard let url = workoutUrlWith(id: id) else { return nil }
        let data = try Data(contentsOf: url)
        return try decoder.decode(Workout.self, from: data)
    }
}
