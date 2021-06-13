//
//  BluetoothHeartRateHandler.swift
//  Fatigue
//
//  Created by Mats Mollestad on 10/06/2021.
//

import Foundation
import Combine

protocol BluetoothHandler {
    func handle(values: Array<UInt8>)
    
    var characteristicID: String { get }
}

protocol HeartBeatHandler {
    var heartRatePublisher: AnyPublisher<Int, Never> { get }
    var rrIntervalPublisher: AnyPublisher<Int, Never> { get }
}

extension String {
    
    func pad(toSize: Int) -> String {
        var padded = self
        guard toSize > self.count else { return self }
        for _ in 0..<(toSize - self.count) {
            padded = "0" + padded
            
        }
        return padded
    }
}

enum ArrayIntegerFormat: Int {
    case format8 = 1
    case format16 = 2
    case format24 = 3
    case format32 = 4
}

extension Int {
    init(value: UInt8, exponent: UInt8) {
        self = Int(value) + Int(exponent) * 256
    }
    
    init(_ values: Array<UInt8>, index: Int, format: ArrayIntegerFormat) {
        // Raw value is the exponent
        self = 0
        for i in 0..<format.rawValue {
            self += Int(values[index + i]) * Int(pow(2, Double(i)))
        }
    }
}

enum HeartRateSensorStatus: Int {
    case notSupported
    case supportedButNoContactDetected
    case supportedWithDetectedContact
}

/// https://www.bluetooth.com/wp-content/uploads/Sitecore-Media-Library/Gatt/Xml/Characteristics/org.bluetooth.characteristic.heart_rate_measurement.xml
/// Flags representing the different heart rate values
struct BluetoothHeartRateFlag {
    
    let flags: [Bool]
    
    init(values: [UInt8]) {
        self.flags = String(Int(values, index: 0, format: .format8), radix: 2)
            .pad(toSize: 8)
            .reversed()
            .map { Int(String($0)) == 1 }
    }
    
    var heartRateFormat: ArrayIntegerFormat {
        if flags[0] {
            return .format16
        } else {
            return .format8
        }
    }
    
    var status: HeartRateSensorStatus {
        if flags[3] {
            // Is value 0 and 1
            return .notSupported
        } else if flags[2] {
            // Is value 3
            return .supportedWithDetectedContact
        } else {
            // Is value 2
            return .supportedButNoContactDetected
        }
    }
    
    var isEnergyExpendedPressent: Bool { flags[4] }
    
    var isRRIntervalsPresent: Bool { flags[5] }
}

struct BluetoothHeartRateHandler: BluetoothHandler, HeartBeatHandler {
    
    var heartRatePublisher: AnyPublisher<Int, Never> { heartRateSubject.eraseToAnyPublisher() }
    var rrIntervalPublisher: AnyPublisher<Int, Never> { rrIntervalSubject.eraseToAnyPublisher() }
    
    private let heartRateSubject = PassthroughSubject<Int, Never>()
    private let rrIntervalSubject = PassthroughSubject<Int, Never>()
    
    var characteristicID: String = "2a37"
    
    func handle(values: Array<UInt8>) {
        
        guard values.count > 1 else { return }
        let flag = BluetoothHeartRateFlag(values: values)
        var valueOffset = 1
        
        let heartRate = Int(values, index: valueOffset, format: flag.heartRateFormat)
        heartRateSubject.send(heartRate)
        valueOffset += flag.heartRateFormat.rawValue
        
        if flag.isEnergyExpendedPressent {
            let energy = Int(values, index: valueOffset, format: .format16)
            print("Energy Expended: \(energy)")
            valueOffset += 2
        }
        
        if flag.isRRIntervalsPresent {
            let rrIntervals = (values.count - valueOffset) / 2
            guard rrIntervals > 0 else { return }
            for i in 0..<rrIntervals {
                let rrInterval = Int(
                    value: values[i * 2 + valueOffset],
                    exponent: values[i * 2 + valueOffset + 1]
                )
                rrIntervalSubject.send(rrInterval)
            }
        }
    }
}
