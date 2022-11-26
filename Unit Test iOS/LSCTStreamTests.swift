//
//  LSCTStreamTests.swift
//  Unit Tests MacOS
//
//  Created by Mats Mollestad on 12/12/2021.
//

import XCTest
@testable import Fatigue

extension Array where Element == Double {
    func meanSquareError(targers: [LSCTStage], startingAt: Int) -> Double? {
        var currentIndex = startingAt
        let totalDuration = targers.map(\.duration).reduce(0, +)
        var error: Double = 0
        var minTargetPower = targers.map(\.targetPower).min() ?? 1
        for target in targers {
            for _ in 0..<target.duration {
                guard currentIndex < self.count else { return nil }
                if target.targetPower == 0 {
                    let fractionalDiff = pow(abs(self[currentIndex] / minTargetPower) + 1, 2) - 1
                    error += fractionalDiff
                } else {
                    let fractionalDiff = pow(abs((self[currentIndex] - target.targetPower) / target.targetPower) + 1, 2) - 1
                    error += fractionalDiff
                }
                currentIndex += 1
            }
        }
        return error / Double(totalDuration)
    }
}

extension WorkoutFrame {
    static func with(power: Int? = nil, heartRate: Int? = nil, cadence: Int? = nil) -> Fatigue.WorkoutFrame {
        WorkoutFrame(
            timestamp: 0,
            power: power.map { Power(value: $0, balance: nil) },
            heartRate: heartRate.map { HeartRate(value: $0, rrIntervals: [], dfaAlpha1: nil) },
            cadence: cadence.map { Cadence(value: $0) }
        )
    }
}

class LSCTStreamTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testLSCTStreamDetector() {
        let targets: [LSCTStage] = [
            .init(duration: 2, targetPower: 20),
            .init(duration: 2, targetPower: 30),
            .init(duration: 2, targetPower: 50),
        ]
        let detector = LSCTStreamDetector(stages: targets, threshold: 0.4)
        let totalDuration = targets.map(\.duration).reduce(0, +)
        let values: [Double] = [10, 20, 25, 30, 40, 50, 60, 67, 40, 50, 60, 67, 20, 20, 30, 30, 50, 50,]
        let meanSquareErrors: [Double] = [
            values.meanSquareError(targers: targets, startingAt: 0)!,
            values.meanSquareError(targers: targets, startingAt: 1)!,
            values.meanSquareError(targers: targets, startingAt: 2)!,
            values.meanSquareError(targers: targets, startingAt: 3)!,
            values.meanSquareError(targers: targets, startingAt: 4)!,
            values.meanSquareError(targers: targets, startingAt: 5)!,
            values.meanSquareError(targers: targets, startingAt: 6)!,
            values.meanSquareError(targers: targets, startingAt: 7)!,
            values.meanSquareError(targers: targets, startingAt: 8)!,
            values.meanSquareError(targers: targets, startingAt: 9)!,
            values.meanSquareError(targers: targets, startingAt: 10)!,
            values.meanSquareError(targers: targets, startingAt: 11)!,
            values.meanSquareError(targers: targets, startingAt: 12)!,
        ]
        var errorIndex = 0
        for value in values {
            detector.add(power: value)
            if detector.valueCount == totalDuration {
                print(meanSquareErrors[errorIndex])
                XCTAssertEqual(meanSquareErrors[errorIndex], detector.meanSquareError, accuracy: 0.0001)
                errorIndex += 1
            }
        }
    }
    
//    func testLapComputation() async throws {
//        let expectedResult = [
//            WorkoutLap(startedAt: 0, duration: 10, powerIntensity: 40),
//            WorkoutLap(startedAt: 10, duration: 40, powerIntensity: 200),
//            WorkoutLap(startedAt: 50, duration: 10, powerIntensity: 100),
//            WorkoutLap(startedAt: 60, duration: 40, powerIntensity: 200),
//            WorkoutLap(startedAt: 100, duration: 10, powerIntensity: 100),
//            WorkoutLap(startedAt: 110, duration: 10, powerIntensity: 40),
//        ]
//        let lapValues = expectedResult.map { lap in
//            (0..<lap.duration).map { _ in WorkoutFrame.with(power: Int(lap.powerIntensity)) }
//        }
//        let values = lapValues.flatMap{ $0 }
//
//        let workout = Workout(id: .init(), startedAt: .init(), values: values, laps: [])
//        workout.summary = Workout.Summary(power: .init(average: 0, normalized: 0, powerBalance: nil, max: 0), heartRate: nil, cadence: nil)
//        let settings = UserSettings(ftp: 230, artifactCorrection: nil, dfaWindow: 120, baselineWorkoutID: nil)
//
//        let computation = ComputeWorkoutLaps(workout: workout, offsetUsed: 4, minDurationForLap: 5)
//        let laps = try await computation.compute(with: settings)
//
//        for (index, lap) in laps.enumerated() {
//            XCTAssertEqual(lap, expectedResult[index])
//        }
//    }
//
//    func testLapComputationWithNoise() async throws {
//        let noiseRange = -5...5
//        let expectedResult = [
//            WorkoutLap(startedAt: 0, duration: 20, powerIntensity: 40),
//            WorkoutLap(startedAt: 20, duration: 40, powerIntensity: 200),
//            WorkoutLap(startedAt: 60, duration: 15, powerIntensity: 100),
//            WorkoutLap(startedAt: 75, duration: 40, powerIntensity: 200),
//            WorkoutLap(startedAt: 115, duration: 15, powerIntensity: 100),
//            WorkoutLap(startedAt: 130, duration: 15, powerIntensity: 40),
//        ]
//        let lapValues = expectedResult.map { lap in
//            (0..<lap.duration).map { _ in WorkoutFrame.with(power: Int(lap.powerIntensity) + Int.random(in: noiseRange)) }
//        }
//        let values = lapValues.flatMap{ $0 }
//
//        let workout = Workout(id: .init(), startedAt: .init(), values: values, laps: [])
//        workout.summary = Workout.Summary(power: .init(average: 0, normalized: 0, powerBalance: nil, max: 0), heartRate: nil, cadence: nil)
//        let settings = UserSettings(ftp: 230, artifactCorrection: nil, dfaWindow: 120, baselineWorkoutID: nil)
//
//        let computation = ComputeWorkoutLaps(workout: workout, offsetUsed: 10, minDurationForLap: 5)
//        let laps = try await computation.compute(with: settings)
//
//        for (index, lap) in laps.enumerated() {
//            let expectedlap = expectedResult[index]
//            XCTAssertEqual(lap.duration, expectedlap.duration)
//            XCTAssertEqual(lap.startedAt, expectedlap.startedAt)
//            XCTAssertTrue(expectedlap.powerIntensity + Double(noiseRange.lowerBound) < lap.powerIntensity, "Recorded too low power \(expectedlap.powerIntensity), should be \(lap.powerIntensity)")
//            XCTAssertTrue(expectedlap.powerIntensity + Double(noiseRange.upperBound) > lap.powerIntensity, "Recorded too high power \(expectedlap.powerIntensity), should be \(lap.powerIntensity)")
//        }
//        XCTAssertEqual(laps, expectedResult)
//    }

}


