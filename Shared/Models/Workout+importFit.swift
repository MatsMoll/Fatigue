//
//  Workout+importFit.swift
//  Fatigue
//
//  Created by Mats Mollestad on 24/06/2021.
//

import Foundation
import FitDataProtocol

extension Workout {
    
    static func importFit(_ url: URL, progress: @escaping (Double) -> Void) throws -> Workout {
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
        var rrIntervals: [Double]?
        var startedAt: Date?
        var powerBalance: PowerBalance?
        
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
                rrIntervals = hrvMessages.map { $0.value }
            }
            
            if let recordMessage = message as? RecordMessage {
                
                if let leftRightBalance = recordMessage.leftRightBalance {
                    powerBalance = PowerBalance(
                        percentage: Double(leftRightBalance.percentContribution) / 100,
                        reference: leftRightBalance.right ? .right : .left
                    )
                }
                
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
                        rrIntervals: rrIntervals,
                        powerBalance: powerBalance
                    )
                )
                heartRate = nil
                power = nil
                cadence = nil
                rrIntervals = nil
                powerBalance = nil
                timestamp += 1
            }
            
            if decodeProgress - lastProgress > 0.01 {
                lastProgress = decodeProgress
                progress(decodeProgress)
            }
        }
        
        return .init(
            id: .init(),
            startedAt: startedAt ?? Date(),
            values: dataFrames,
            powerCurve: nil
        )
    }
}
