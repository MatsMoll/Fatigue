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

struct BluetoothHeartRateHandler: BluetoothHandler, HeartBeatHandler {
    
    var heartRatePublisher: AnyPublisher<Int, Never> { heartRateSubject.eraseToAnyPublisher() }
    var rrIntervalPublisher: AnyPublisher<Int, Never> { rrIntervalSubject.eraseToAnyPublisher() }
    
    private let heartRateSubject = PassthroughSubject<Int, Never>()
    private let rrIntervalSubject = PassthroughSubject<Int, Never>()
    
    var characteristicID: String = "2a37"
    
    func handle(values: Array<UInt8>) {
        
        guard values.count > 1 else { return }
        
        heartRateSubject.send(Int(values[1]))
        
        if values.count > 2 {
            let rrIntervals = (values.count - 2) / 2
            for i in 0..<rrIntervals {
                let rrInterval = Int(values[i * 2 + 2]) + Int(values[i * 2 + 3]) * 256
                rrIntervalSubject.send(rrInterval)
            }
        }
    }
}
