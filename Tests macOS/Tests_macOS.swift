//
//  Tests_macOS.swift
//  Tests macOS
//
//  Created by Mats Mollestad on 29/05/2021.
//

import XCTest
@testable import Fatigue

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
    
    func testHeartRateHandler() {
        let rrInterval = 1084
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
