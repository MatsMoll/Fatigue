//
//  WorkoutStore.swift
//  Fatigue
//
//  Created by Mats Mollestad on 29/05/2021.
//

import Foundation
import FitDataProtocol

struct GenericError: Error {
    let reason: String
    
    init(reason: String) {
        self.reason = reason
    }
}


class WorkoutStore: ObservableObject {
    
    @Published
    var workouts: [WorkoutSessionViewModel] = []
    
    func importFit(_ url: URL, progress: @escaping (Double) -> Void) throws {
        guard url.startAccessingSecurityScopedResource() else {
            throw GenericError(reason: "Couldn’t be opened because you don’t have permission to view it.")
        }
        defer {
            url.stopAccessingSecurityScopedResource()
        }
        let data = try Data(contentsOf: url)
        
        var dataFrames: [Workout.DataFrame] = []
        
        var timestamp = 0
        var heartRate: Int?
        var power: Int?
        var cadence: Int?
        var rrIntervals: [Int]?
        var startedAt: Date?
        
//        let numberOfMessages = file.messages.count
        var lastProgress: Double = 0
        progress(lastProgress)
        
        
        var decoder =  FitFileDecoder(crcCheckingStrategy: .throws)
        try decoder.decode(data: data, messages: FitFileDecoder.defaultMessages) { (message, decodeProgress) in
            
            if
                let activityMessage = message as? ActivityMessage,
                let startDate = activityMessage.timeStamp?.recordDate,
                startedAt == nil
            {
                startedAt = startDate
            }
            
            if
                let hrvMessage = message as? HrvMessage,
                let hrvMessages = hrvMessage.hrv
            {
                rrIntervals = hrvMessages.map { Int($0.value * 1000) }
            }
            
            if let recordMessage = message as? RecordMessage {
                
                if let powerValue = recordMessage.power {
                    power = Int(powerValue.value)
                }
                
                if let cadenceValue = recordMessage.cadence {
                    cadence = Int(cadenceValue.value)
                }
                
                if let heartRateValue = recordMessage.heartRate {
                    heartRate = Int(heartRateValue.value)
                }
                
                dataFrames.append(
                    .init(
                        timestamp: timestamp,
                        heartRate: heartRate,
                        power: power,
                        cadence: cadence,
                        rrIntervals: rrIntervals
                    )
                )
                heartRate = nil
                power = nil
                cadence = nil
                rrIntervals = nil
                timestamp += 1
            }
            
            if decodeProgress - lastProgress > 0.01 {
                lastProgress = decodeProgress
                progress(decodeProgress)
            }
        }
//
        
        DispatchQueue.main.async { [weak self] in
            self?.workouts.append(
                WorkoutSessionViewModel.init(
                    workout:
                        Workout(
                            id: .init(),
                            startedAt: startedAt ?? Date(),
                            values: dataFrames
                        )
                )
            )
        }
    }
}
