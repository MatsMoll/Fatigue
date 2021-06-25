//
//  LSCTAnalysis.swift
//  Fatigue
//
//  Created by Mats Mollestad on 13/06/2021.
//

import Foundation

struct RegressionResult: Codable {
    /// The alpha value in the equation a + b * x = y
    let alpha: Double
    
    /// The beta value in the equation a + b * x = y
    let beta: Double
}

struct LSCTStageSummary: Codable {
    
    /// The duration in seconds
    let duration: Int
    
    /// The average heart rate in the stage
    let averageHeartRate: Double?
    
    
    let averagePower: Double?
    
    
    let averageCadence: Double?
    
    
    let averageDfaAlpha1: Double?
}

struct LSCTConfig {
    
    let power: Significanse
    let cadence: Significanse
    let dfaAlpha: Significanse
    let heartRate: Significanse
    let heartRateRecovery: Significanse
    
    struct Significanse: Codable {
        let value: Double
        let method: ComparisonMethod
        let wantedDevelopment: DevelopemntDirections
        
        func development(value compareValue: Double) -> LSCTResult.Subresult.ValueDevelopment {
            if abs(compareValue) >= value {
                if wantedDevelopment.sign == compareValue.sign {
                    return .significantBetter
                } else {
                    return .significantWorse
                }
            } else {
                return .insignificant
            }
        }
    }
    
    enum DevelopemntDirections: Int, Codable {
        case higher
        case lower
        case stable
        
        var sign: FloatingPointSign? {
            switch self {
            case .higher: return .plus
            case .lower: return .minus
            default: return nil
            }
        }
    }
    
    enum ComparisonMethod: Int, Codable {
        case relative
        case absolute
    }
    
    static let `default` = LSCTConfig(
        power: .init(value: 0.06, method: .relative, wantedDevelopment: .higher),
        cadence: .init(value: 0.06, method: .relative, wantedDevelopment: .stable),
        dfaAlpha: .init(value: 0.06, method: .relative, wantedDevelopment: .higher),
        heartRate: .init(value: 0.06, method: .relative, wantedDevelopment: .lower),
        heartRateRecovery: .init(value: 5, method: .absolute, wantedDevelopment: .lower)
    )
}

struct LSCTResult: Codable {
    
    struct HeartRateSubresults: Codable {
        let lastStageDiff: Subresult
        let intensityResponse: LinearRegression.Result
        let hrrAnalysis: Subresult
    }
    
    struct Subresult: Codable {
        
        enum ValueDevelopment: Int, Codable {
            case insignificant
            case significantBetter
            case significantWorse
        }
        
        let relativDifferance: Double
        let absoluteDifferance: Double
        let development: ValueDevelopment
    }
    
    let power: Subresult?
    let cadence: Subresult?
    let dfaAlpha1: Subresult?
    
    // HR Values
    let heartRate: HeartRateSubresults?
    
    /// An identifer that presents which run is used as baseline
    let baselineRunIdentifier: LSCTRun.Identifier
    
    /// THe identifier of the processed run
    let runIdentifer: LSCTRun.Identifier
}

struct LSCTRun: Codable {
    
    struct Identifier: Codable {
        /// When the run starts at
        let startingAt: Int
        
        /// The date the workout starts
        let workoutDate: Date
    }
    
    /// The total duration of all the stages
    var totalDuration: Int {
        // Sums all the durations together
        stages.map(\.duration).reduce(0, +)
    }
    
    /// A summary of all the different stages
    let stages: [LSCTStageSummary]
    
    /// How well the heart rate respons from the begining to the end of the warmup
    let heartRateResponse: RegressionResult?
    
    /// How much the heart rate reduces when stopping the intervals
    let hrrAnalysis: RegressionResult?
    
    /// Identifing which run it is
    let identifier: Identifier
    
    func compare(with baseline: LSCTRun, lsctConfig: LSCTConfig = .default) throws -> LSCTResult {
        guard baseline.totalDuration == totalDuration else { throw LSCTAnalysisError.tooFewValuesInWorkout }
        guard
            let lastStageBaseline = baseline.stages.last,
            let lastStage = stages.last
        else { throw LSCTAnalysisError.missingLastStage }
        
        let powerDiff       = subresult(\.averagePower,     baseline: lastStageBaseline, summary: lastStage, significanse: lsctConfig.power)
        let cadenceDiff     = subresult(\.averageCadence,   baseline: lastStageBaseline, summary: lastStage, significanse: lsctConfig.cadence)
        let dfaAlpha1Diff   = subresult(\.averageDfaAlpha1, baseline: lastStageBaseline, summary: lastStage, significanse: lsctConfig.dfaAlpha)
        let heartRateDiff   = subresult(\.averageHeartRate, baseline: lastStageBaseline, summary: lastStage, significanse: lsctConfig.heartRate)
        
        var heartRateSubresult: LSCTResult.HeartRateSubresults?
        
        if let heartRateDiff = heartRateDiff {
            
            var intensityResponse: LinearRegression.Result = .init(alpha: 0, beta: 0)
            var returnedHrrAnalysis: LSCTResult.Subresult = .init(relativDifferance: 0, absoluteDifferance: 0, development: .insignificant)
            
            if
                let baselineHeartRateResponse = baseline.heartRateResponse,
                let heartRateResponse = heartRateResponse
            {
                intensityResponse = LinearRegression.Result(
                    alpha: heartRateResponse.alpha - baselineHeartRateResponse.alpha,
                    beta: heartRateResponse.beta - baselineHeartRateResponse.beta
                )
            }
            if
                let baselineHrr = baseline.hrrAnalysis,
                let hrrAnalysis = hrrAnalysis
            {
                let absDiff = hrrAnalysis.alpha - baselineHrr.alpha
                returnedHrrAnalysis = LSCTResult.Subresult(
                    relativDifferance: absDiff / baselineHrr.alpha,
                    absoluteDifferance: absDiff,
                    development: lsctConfig.heartRateRecovery.development(value: absDiff)
                )
            }
            heartRateSubresult = LSCTResult.HeartRateSubresults(
                lastStageDiff: heartRateDiff,
                intensityResponse: intensityResponse,
                hrrAnalysis: returnedHrrAnalysis
            )
        }
        
        return LSCTResult(
            power: powerDiff,
            cadence: cadenceDiff,
            dfaAlpha1: dfaAlpha1Diff,
            heartRate: heartRateSubresult,
            baselineRunIdentifier: baseline.identifier,
            runIdentifer: identifier
        )
    }
    
    func subresult(_ valuePath: KeyPath<LSCTStageSummary, Double?>, baseline: LSCTStageSummary, summary: LSCTStageSummary, significanse: LSCTConfig.Significanse) -> LSCTResult.Subresult? {
        guard
            let baselineValue = baseline[keyPath: valuePath],
            let value = summary[keyPath: valuePath]
        else { return nil }
        let absoluteDiff = value - baselineValue
        let relativeDiff = absoluteDiff / baselineValue
        
        let compareValue = significanse.method == .absolute ? absoluteDiff : relativeDiff
        
        return LSCTResult.Subresult(
            relativDifferance: relativeDiff,
            absoluteDifferance: absoluteDiff,
            development: significanse.development(value: compareValue)
        )
    }
}

struct LSCTAnalysisError: Error {
    let reason: String
    
    static let tooFewValuesInReference = LSCTAnalysisError(reason: "Too few values in the reference file after the starting point")
    static let tooFewValuesInWorkout = LSCTAnalysisError(reason: "Too few values in the workout file after the starting point")
    static let missingLastStage = LSCTAnalysisError(reason: "Missing the last stage")
}

extension Workout {
    func lsctRun(startingAt: Int, stageDurations: [Int], hrrDuration: Int) throws -> LSCTRun {
        let totalDuration = hrrDuration + stageDurations.reduce(0, +)
        guard startingAt + totalDuration < values.count else { throw LSCTAnalysisError.tooFewValuesInReference }
        
        var stageSummaries = [LSCTStageSummary]()
        for stageDuration in stageDurations {
            var heartRateSum: Double = 0
            var powerSum: Double = 0
            var cadenceSum: Double = 0
            var dfaAlphaSum: Double = 0
            for stageIndex in 0..<stageDuration {
                let index = startingAt + stageIndex
                if let heartRate = values[index].heartRate {
                    heartRateSum += Double(heartRate)
                }
                if let power = values[index].power {
                    powerSum += Double(power)
                }
                if let cadence = values[index].cadence {
                    cadenceSum += Double(cadence)
                }
                if let dfaAlpha1 = values[index].dfaAlpha1 {
                    dfaAlphaSum += dfaAlpha1
                }
            }
            stageSummaries.append(
                .init(
                    duration: stageDuration,
                    averageHeartRate: heartRateSum != 0 ? heartRateSum / Double(stageDuration) : nil,
                    averagePower: powerSum != 0 ? powerSum / Double(stageDuration) : nil,
                    averageCadence: cadenceSum != 0 ? cadenceSum / Double(stageDuration) : nil,
                    averageDfaAlpha1: dfaAlphaSum != 0 ? dfaAlphaSum / Double(stageDuration) : nil
                )
            )
        }
        var heartRateResponse: RegressionResult?
        var hrrAnalysis: RegressionResult?
        if
            let firstHeartRateValue = stageSummaries.first?.averageHeartRate,
            let lastHeartRateValue = stageSummaries.last?.averageHeartRate
        {
            heartRateResponse = .init(
                alpha: firstHeartRateValue,
                beta: (lastHeartRateValue - firstHeartRateValue) / Double(totalDuration - hrrDuration)
            )
        }
        if
            let hrrStartValue = values[startingAt + totalDuration - hrrDuration].heartRate,
            let hrrEndValue = values[startingAt + totalDuration].heartRate
        {
            hrrAnalysis = .init(
                alpha: Double(hrrStartValue),
                beta: Double(hrrEndValue - hrrStartValue) / Double(hrrDuration)
            )
        }
        return LSCTRun(
            stages: stageSummaries,
            heartRateResponse: heartRateResponse,
            hrrAnalysis: hrrAnalysis,
            identifier: .init(
                startingAt: startingAt,
                workoutDate: self.startedAt
            )
        )
    }
}

class LSCTAnalysis {
    internal init(analysisStartingPoint: Int, analysisWorkout: Workout, referenceStartingPoint: Int, referenceWorkout: Workout, stepDurations: [Int], hrrDuration: Int) {
        self.analysisStartingPoint = analysisStartingPoint
        self.analysisWorkout = analysisWorkout
        self.referenceStartingPoint = referenceStartingPoint
        self.referenceWorkout = referenceWorkout
        self.stepDurations = stepDurations
        self.hrrDuration = hrrDuration
    }
    
    
    let analysisStartingPoint: Int
    let analysisWorkout: Workout
    
    let referenceStartingPoint: Int
    let referenceWorkout: Workout
    
    let stepDurations: [Int]
    let hrrDuration: Int
    
    func analyse() throws {
        let totalStageDuration = stepDurations.reduce(0, +)
        guard referenceWorkout.values.count > referenceStartingPoint + totalStageDuration else {
            throw LSCTAnalysisError.tooFewValuesInReference
        }
        guard analysisWorkout.values.count > analysisStartingPoint + totalStageDuration else {
            throw LSCTAnalysisError.tooFewValuesInReference
        }
    }
}
