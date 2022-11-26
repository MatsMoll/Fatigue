//
//  Tests_iOS.swift
//  Tests iOS
//
//  Created by Mats Mollestad on 29/05/2021.
//

import XCTest
import Algorithms
@testable import Fatigue

extension Array where Element == Double {
    func meanSquareError(targers: [LSCTStage], startingAt: Int) -> Double? {
        var currentIndex = startingAt
        let totalDuration = targers.map(\.duration).reduce(0, +)
        var error: Double = 0
        let minTargetPower = targers.map(\.targetPower).min() ?? 1
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

class Tests_iOS: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is call ed before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExample() throws {
        // UI tests must launch the application that they test.
//        let powerUUID = BluetoothDevice.DeviceType.powerMeter.uuid

        // Use recording to get started writing UI tests.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
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
        XCTAssertEqual(detector.detection?.frameWorkout, 12)
    }

    func testLaunchPerformance() throws {
        if #available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 7.0, *) {
            // This measures how long it takes to launch your application.
            measure(metrics: [XCTApplicationLaunchMetric()]) {
                XCUIApplication().launch()
            }
        }
    }
    
    func testLapComputation() async throws {
        let expectedResult = [
            WorkoutLap(startedAt: 0, duration: 10, powerIntensity: 40),
            WorkoutLap(startedAt: 10, duration: 40, powerIntensity: 200),
            WorkoutLap(startedAt: 50, duration: 10, powerIntensity: 100),
            WorkoutLap(startedAt: 60, duration: 40, powerIntensity: 200),
            WorkoutLap(startedAt: 100, duration: 10, powerIntensity: 100),
            WorkoutLap(startedAt: 110, duration: 10, powerIntensity: 40),
        ]
        let lapValues = expectedResult.map { lap in
            (0..<lap.duration).map { _ in WorkoutFrame.with(power: Int(lap.powerIntensity)) }
        }
        let values = lapValues.flatMap{ $0 }
        
        let workout = Workout(id: .init(), startedAt: .init(), values: values, laps: [])
        let settings = UserSettings(ftp: 230, artifactCorrection: nil, dfaWindow: 120, baselineWorkoutID: nil)
        
        let computation = ComputeWorkoutLaps(workout: workout, offsetUsed: 5, minDurationForLap: 8)
        let laps = try await computation.compute(with: settings)
        
        XCTAssertEqual(laps, expectedResult)
    }
}
