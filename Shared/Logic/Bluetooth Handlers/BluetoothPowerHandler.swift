//
//  BluetoothPowerHandler.swift
//  Fatigue
//
//  Created by Mats Mollestad on 11/06/2021.
//

import Foundation
import Combine

protocol PowerHandler {
    var powerPublisher: AnyPublisher<Int, Never> { get }
}

struct BluetoothPowerHandler: PowerHandler, BluetoothHandler {
    
    var powerPublisher: AnyPublisher<Int, Never> { powerSubject.eraseToAnyPublisher() }
    
    private let powerSubject = PassthroughSubject<Int, Never>()
    
    var characteristicID: String = "2a63"
    
    func handle(values: Array<UInt8>) {
        
        let flag = Int(values[0]) + Int(values[1]) * 256
        
        let power = Int(values[2]) + Int(values[3]) * 256
        powerSubject.send(power)
        
        print(flag)
    }
}
