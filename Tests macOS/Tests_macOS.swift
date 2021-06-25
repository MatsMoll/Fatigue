//
//  Tests_macOS.swift
//  Tests macOS
//
//  Created by Mats Mollestad on 29/05/2021.
//

import XCTest
import Algorithms
import Fatigue

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

class Tests_macOS: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        
        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExample() throws {
        // UI tests must launch the application that they test.
        let app = XCUIApplication()
        app.launch()

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
    }
    
    func testHeartRateHandler() {
        let rrInterval: Double = 1084 / 1024
        let heartRate = 59
        let values: [UInt8] = [16, 59, 60, 4]
        
        let heartRateExpection = XCTestExpectation()
        let rrIntervalExection = XCTestExpectation()
        
        let flag = BluetoothHeartRateFlag(values: values)
        
        XCTAssertEqual(flag.heartRateFormat, .format8)
        XCTAssertEqual(flag.isEnergyExpendedPresent, false)
        XCTAssertEqual(flag.isRRIntervalsPresent, true)
        
        let handler = BluetoothHeartRateHandler()
        let hrListner = handler.heartRatePublisher.sink { recivedHeartRate in
            XCTAssertEqual(recivedHeartRate, heartRate)
            heartRateExpection.fulfill()
        }
        let rrListner = handler.rrIntervalPublisher.sink { revicedRrInterval in
            XCTAssertEqual(rrInterval, revicedRrInterval)
            rrIntervalExection.fulfill()
        }
        handler.handle(values: values)
        
        wait(for: [heartRateExpection, rrIntervalExection], timeout: 1)
    }
    
    func testPowerHandler() {
        
        let power = 1
        let balance = PowerBalance(
            percentage: 100,
            reference: .left
        )
        let values: [UInt8] = [47, 0, 1, 0, 200, 46, 0, 19, 0, 124, 57]
        
        let powerExpection = XCTestExpectation()
        let balanceExpection = XCTestExpectation()
        
        let flag = BluetoothPowerFlag(values: values)
        
        XCTAssertEqual(flag.isCrankRevolutionPresent, true)
        XCTAssertEqual(flag.isPowerBalancePresent, true)
        XCTAssertEqual(flag.isAccumulatedTorquePresent, true)
        XCTAssertEqual(flag.isWheelRevolutionPresent, false)
        XCTAssertEqual(flag.isExtremeForceMagnitudePresent, false)
        XCTAssertEqual(flag.isExtremeTorqueMagnitudePresent, false)
        XCTAssertEqual(flag.isExtremeAnglePresent, false)
        XCTAssertEqual(flag.isTopDeadSpotAnglePresent, false)
        XCTAssertEqual(flag.isBottomDeadSpotAnglePresent, false)
        XCTAssertEqual(flag.isAccumulatedEnergyPresent, false)
        
        let handler = BluetoothPowerHandler()
        let powerListner = handler.powerPublisher.sink { recivedPower in
            XCTAssertEqual(power, recivedPower)
            powerExpection.fulfill()
        }
        let balanceListner = handler.pedalPowerBalancePublisher.sink { recivedBalance in
            XCTAssertEqual(recivedBalance, balance)
            balanceExpection.fulfill()
        }
        handler.handle(values: values)
        
        wait(for: [powerExpection, balanceExpection], timeout: 1)
    }
    
    func testDFAStreamModel() {
        let (beatToBeatVar, expectedValue) = DFAStreamModel.testData
        
        let model = DFAStreamModel()
        
        for value in beatToBeatVar {
            model.add(value: value)
        }
        let result = try! model.compute()
        XCTAssertEqual(result.beta, expectedValue, accuracy: 0.0001)
    }

    func testLaunchPerformance() throws {
        if #available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 7.0, *) {
            // This measures how long it takes to launch your application.
            measure(metrics: [XCTApplicationLaunchMetric()]) {
                XCUIApplication().launch()
            }
        }
    }
}
