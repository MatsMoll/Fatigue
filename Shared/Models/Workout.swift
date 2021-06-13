//
//  Workout.swift
//  Fatigue
//
//  Created by Mats Mollestad on 03/06/2021.
//

import Foundation
import Combine
import FitDataProtocol

struct Workout: Identifiable, Codable {
    
    struct PowerSummary: Codable {
        let average: Int
        let normalized: Int
    }
    
    struct HeartRateSummary: Codable {
        let average: Int
    }
    
    struct DFAAlphaSummary: Codable {
        let average: Double
    }
    
    struct CadenceSummary: Codable {
        let average: Int
    }
    
    enum UpdateError: Error {
        case invalidValueLength
    }
    
    struct DataFrame: Codable {
        internal init(timestamp: Int, heartRate: Int? = nil, power: Int? = nil, cadence: Int? = nil, dfaAlpha1: Double? = nil, rrIntervals: [Int]? = nil, ratingOfPervicedEffort: Int? = nil) {
            self.timestamp = timestamp
            self.heartRate = heartRate
            self.power = power
            self.cadence = cadence
            self.dfaAlpha1 = dfaAlpha1
            self.rrIntervals = rrIntervals
            self.ratingOfPervicedEffort = ratingOfPervicedEffort
        }
        
        let timestamp: Int
        let heartRate: Int?
        let power: Int?
        let cadence: Int?
        let dfaAlpha1: Double?
        let rrIntervals: [Int]?
        let ratingOfPervicedEffort: Int?
    }
    
    let id: UUID
    let startedAt: Date
    
    private (set) var values: [DataFrame]
    
    var powerCurve: MeanMaximalPower.Curve?
    
    var powerSummary: PowerSummary?
    var heartRateSummary: HeartRateSummary?
    var dfaAlphaSummary: DFAAlphaSummary?
    var cadenceSummary: CadenceSummary?
    
    var elapsedTime: Int {
        values.last?.timestamp ?? 0
    }
    
    var hasDFAValues: Bool { dfaAlphaSummary != nil }
    
    internal init(id: UUID, startedAt: Date, values: [Workout.DataFrame], powerCurve: MeanMaximalPower.Curve?) {
        self.id = id
        self.startedAt = startedAt
        self.values = values
        self.powerCurve = powerCurve
        
        self.calculateSummary()
    }
    
    mutating func calculateSummary() {
        if powerSummary == nil {
            computePowerSummary(values: values.compactMap(\.power).map(Double.init))
        }
        if dfaAlphaSummary == nil {
            computeDfaSummary(values: values.compactMap(\.dfaAlpha1))
        }
        if heartRateSummary == nil {
            computeHeartRateSummary(values: values.compactMap(\.heartRate).map(Double.init))
        }
        if cadenceSummary == nil {
            computeCadenceSummary(values: values.compactMap(\.cadence).map(Double.init))
        }
    }
    
    mutating func computePowerSummary(values: [Double]) {
        guard !values.isEmpty else { return }
        powerSummary = PowerSummary(
            average: Int(values.average()),
            normalized: NormalizedPowerModel.compute(values: values)
        )
    }
    
    mutating func computeHeartRateSummary(values: [Double]) {
        guard !values.isEmpty else { return }
        heartRateSummary = HeartRateSummary(
            average: Int(values.average())
        )
    }
    
    mutating func computeDfaSummary(values: [Double]) {
        guard !values.isEmpty else { return }
        dfaAlphaSummary = DFAAlphaSummary(
            average: values.average()
        )
    }
    
    mutating func computeCadenceSummary(values: [Double]) {
        guard !values.isEmpty else { return }
        cadenceSummary = CadenceSummary(
            average: Int(values.average())
        )
    }
    
    mutating func update(dfaAlpha: [Double]) throws {
        guard dfaAlpha.count == values.count else { throw UpdateError.invalidValueLength }
        for (index, frame) in values.enumerated() {
            values[index] = Workout.DataFrame(
                timestamp: frame.timestamp,
                heartRate: frame.heartRate,
                power: frame.power,
                cadence: frame.cadence,
                dfaAlpha1: dfaAlpha[index],
                rrIntervals: frame.rrIntervals,
                ratingOfPervicedEffort: frame.ratingOfPervicedEffort
            )
        }
        computeDfaSummary(values: dfaAlpha)
    }
}


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
        
        return .init(
            id: .init(),
            startedAt: startedAt ?? Date(),
            values: dataFrames,
            powerCurve: nil
        )
    }
}

extension Array where Element == Double {
    func average() -> Double {
        guard !isEmpty else { return .nan }
        var sum: Double = 0
        for value in self {
            sum += value
        }
        return sum / Double(self.count)
    }
}

extension Array where Element == Int {
    func average() -> Double {
        guard !isEmpty else { return .nan }
        var sum: Int = 0
        for value in self {
            sum += value
        }
        return Double(sum) / Double(self.count)
    }
}
