//
//  ComputeWorkoutLaps.swift
//  Fatigue
//
//  Created by Mats Mollestad on 11/12/2021.
//

import Foundation

public struct WorkoutLap: Identifiable, Equatable {
    
    public let id: UUID
    public let lapNumber: Int
    public let startedAt: Int
    public let duration: Int
    public var endedAt: Int { startedAt + duration }
    
    public let power: Workout.PowerSummary?
    public let heartRate: Workout.HeartRateSummary?
    public let cadence: Workout.CadenceSummary?
    
    public init(lapNumber: Int, startedAt: Int, duration: Int, summary: Workout.Summary, id: UUID = UUID()) {
        self.id = id
        self.lapNumber = lapNumber
        self.startedAt = startedAt
        self.duration = duration
        self.power = summary.power
        self.heartRate = summary.heartRate
        self.cadence = summary.cadence
    }
}

public struct ComputeWorkoutLaps: ComputationalTask {
    
    public let workout: Workout
    let offsetUsed: Int
    let minDurationForLap: Int
    
    public init(workout: Workout, offsetUsed: Int = 15, minDurationForLap: Int = 20) {
        self.workout = workout
        self.offsetUsed = offsetUsed
        self.minDurationForLap = minDurationForLap
    }
    
    public func compute(with settings: UserSettings) async throws -> [WorkoutLap] {
        guard let ftp = settings.ftp, workout.hasPower else {
            throw GenericError(reason: "Missing power data")
        }
        let powerData = workout.frames.compactMap(\.power?.value)
        
        // 10% of the ftp = a change in lap
        let lapDeltaThreshold = Double(ftp) * 0.05
        // Rolling average with 10 sec
        let rollingAvgAndStd = powerData.rollingAndStd(over: offsetUsed)
        let rollingAverage = rollingAvgAndStd.map(\.average)
//        let standardDiviation = rollingAvgAndStd.map(\.std)
        let delta = rollingAverage.deltaDifferance(offset: offsetUsed)
        
        var laps = [Int]()
        var lastStoredChange: Int = 0
        
        var startChangeAt: Int = 0
        var endChangeAt: Int = 0
        
        for index in 0..<rollingAverage.count {
            guard delta[index].isNormal else { continue }
            
            let duration = endChangeAt - lastStoredChange
            
            if abs(delta[index]) > lapDeltaThreshold {
                endChangeAt = index
                if lastStoredChange == startChangeAt {
                    startChangeAt = index
                }
                continue
            }
            
            if duration > minDurationForLap {
                laps.append(duration)
                lastStoredChange = endChangeAt
                startChangeAt = endChangeAt
            }
        }
        guard laps.count > 0 else { throw GenericError(reason: "No laps detected")}
        // Offset the laps by the change and add the removed offset to the last lap
        laps[0] -= offsetUsed
        laps[laps.count - 1] += offsetUsed
        return try await ComputeWorkoutLapsSummaries(workout: workout, laps: laps).compute(with: settings)
    }
}

public struct ComputeWorkoutLapsSummaries: ComputationalTask {
    
    public let workout: Workout
    let laps: [Int]
    
    public init(workout: Workout, laps: [Int]) {
        self.workout = workout
        self.laps = laps
    }
    
    public func compute(with settings: UserSettings) async throws -> [WorkoutLap] {
        
        var summaries = [WorkoutLap]()
        var startedAt = 0
        let lastIndex = workout.frames.count - 1
        for lap in laps {
            let endIndex = min(lastIndex, startedAt + lap - 1)
            let frames = Array(workout.frames[startedAt...endIndex])
            let subWorkout = Workout(id: .init(), startedAt: .init(), values: frames, laps: [])
            let summary = try await SummaryWorkoutComputation(workout: subWorkout).compute(with: settings)
            summaries.append(
                WorkoutLap(
                    lapNumber: summaries.count + 1,
                    startedAt: startedAt,
                    duration: lap,
                    summary: summary
                )
            )
            startedAt += lap
        }
        return summaries
    }
}
