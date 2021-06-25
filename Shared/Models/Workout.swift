//
//  Workout.swift
//  Fatigue
//
//  Created by Mats Mollestad on 03/06/2021.
//

import Foundation
import Combine

struct Workout: Identifiable, Codable {
    
    struct PowerSummary: Codable {
        let average: Int
        let normalized: Int
        let powerBalance: PowerBalance?
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
        internal init(
            timestamp: Int,
            heartRate: Int? = nil,
            power: Int? = nil,
            cadence: Int? = nil,
            dfaAlpha1: Double? = nil,
            rrIntervals: [Double]? = nil,
            ratingOfPervicedEffort: Int? = nil,
            powerBalance: PowerBalance? = nil
        ) {
            self.timestamp = timestamp
            self.heartRate = heartRate
            self.power = power
            self.cadence = cadence
            self.dfaAlpha1 = dfaAlpha1
            self.rrIntervals = rrIntervals
            self.ratingOfPervicedEffort = ratingOfPervicedEffort
            self.powerBalance = powerBalance
        }
        
        let timestamp: Int
        let heartRate: Int?
        let power: Int?
        let cadence: Int?
        let dfaAlpha1: Double?
        let rrIntervals: [Double]?
        let ratingOfPervicedEffort: Int?
        let powerBalance: PowerBalance?
    }
    
    let id: UUID
    let startedAt: Date
    
    private (set) var values: [DataFrame]
    
    var powerCurve: MeanMaximalPower.Curve?
    
    var lsctDetection: LSCTDetector.Detection?
    
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
            computePowerSummary(
                values: values.compactMap(\.power).map(Double.init),
                powerBalance: values.compactMap(\.powerBalance)
            )
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
    
    mutating func computePowerSummary(values: [Double], powerBalance: [PowerBalance]) {
        guard !values.isEmpty else { return }
        var balance: PowerBalance?
        if let firstBalance = powerBalance.first {
            balance = PowerBalance(
                percentage: powerBalance.map(\.percentage).average(),
                reference: firstBalance.reference
            )
        }
        powerSummary = PowerSummary(
            average: Int(values.average()),
            normalized: NormalizedPowerModel.compute(values: values),
            powerBalance: balance
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

struct GenericError: Error {
    let reason: String
    
    init(reason: String) {
        self.reason = reason
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

extension Workout.DataFrame {
    struct Old: Codable {
        var elapsedSeconds: Int
        var power: Int?
        var heartRate: Int?
        var cadence: Int?
        var ratingOfPervicedEffort: Int?
        var rrInterval: [Int]?
        var dfaAlpha: Double?
        
        var frame: Workout.DataFrame {
            .init(
                timestamp: elapsedSeconds,
                heartRate: heartRate,
                power: power,
                cadence: cadence,
                dfaAlpha1: dfaAlpha,
                rrIntervals: rrInterval?.map { Double($0) / 1000 },
                ratingOfPervicedEffort: ratingOfPervicedEffort
            )
        }
    }
}

extension Workout {
    struct Old: Codable {
        let id: UUID?
        let dataPoints: [DataFrame.Old]
        let startedAt: Date?
        
        var workout: Workout {
            .init(
                id: id ?? .init(),
                startedAt: startedAt ?? .init(),
                values: dataPoints.map(\.frame),
                powerCurve: nil
            )
        }
    }
}
