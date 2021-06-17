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
    var rrIntervalPublisher: AnyPublisher<Double, Never> { get }
}

struct BluetoothHeartRateHandler: BluetoothHandler, HeartBeatHandler {
    
    var heartRatePublisher: AnyPublisher<Int, Never> { heartRateSubject.eraseToAnyPublisher() }
    var rrIntervalPublisher: AnyPublisher<Double, Never> { rrIntervalSubject.eraseToAnyPublisher() }
    
    private let heartRateSubject = PassthroughSubject<Int, Never>()
    private let rrIntervalSubject = PassthroughSubject<Double, Never>()
    
    let characteristicID: String = "2A37"
    
    func handle(values: Array<UInt8>) {
        
        guard values.count > 1 else { return }
        let flag = BluetoothHeartRateFlag(values: values)
        var valueOffset = 1
        
        let heartRate = Int(values, index: &valueOffset, format: flag.heartRateFormat)
        heartRateSubject.send(heartRate)
        
        if flag.isEnergyExpendedPresent {
            let energy = Int(values, index: &valueOffset, format: .format16)
            print("Energy Expended: \(energy)")
        }
        
        if flag.isRRIntervalsPresent {
            let rrIntervals = (values.count - valueOffset) / 2
            guard rrIntervals > 0 else { return }
            for _ in 0..<rrIntervals {
                let rrInterval = Double(
                    values,
                    index: &valueOffset,
                    format: .format16,
                    exponent: -10
                )
                rrIntervalSubject.send(rrInterval)
            }
        }
    }
}
