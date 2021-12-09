//
//  BluetoothHeartRateHandler.swift
//  Fatigue
//
//  Created by Mats Mollestad on 10/06/2021.
//

import Foundation
import Combine

struct HeartRateDeviceValue: Codable {
    let heartRate: Int
    let rrIntervals: [Double]
}

protocol HeartRateHandler: BluetoothHandler {
    var heartRateListner: AnyPublisher<HeartRateDeviceValue, Never> { get }
}

struct BluetoothHeartRateHandler: BluetoothHandler, HeartRateHandler {
    
    var heartRateListner: AnyPublisher<HeartRateDeviceValue, Never> { valuesSubject.eraseToAnyPublisher() }
    private let valuesSubject = PassthroughSubject<HeartRateDeviceValue, Never>()
    
    var characteristic: BluetoothCharacteristics = .heartRateMeasurement
    
    func handle(values: Array<UInt8>) {
        
        guard values.count > 1 else { return }
        let flag = BluetoothHeartRateFlag(values: values)
        var valueOffset = 1
        
        let heartRate = Int(values, index: &valueOffset, format: flag.heartRateFormat)
        var rrIntervals: [Double] = []
        
        if flag.isEnergyExpendedPresent {
            let energy = Int(values, index: &valueOffset, format: .format16)
            print("Energy Expended: \(energy)")
        }
        
        if flag.isRRIntervalsPresent {
            let rrIntervalsCount = (values.count - valueOffset) / 2
            guard rrIntervalsCount > 0 else { return }
            for _ in 0..<rrIntervalsCount {
                rrIntervals.append(
                    Double(
                        values,
                        index: &valueOffset,
                        format: .format16,
                        exponent: -10
                    )
                )
            }
        }
        
        valuesSubject.send(
            HeartRateDeviceValue(
                heartRate: heartRate,
                rrIntervals: rrIntervals
            )
        )
    }
}
