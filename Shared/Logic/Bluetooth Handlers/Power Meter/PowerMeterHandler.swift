//
//  PowerMeterHandler.swift
//  Fatigue
//
//  Created by Mats Mollestad on 17/06/2021.
//

import Foundation
import Combine

struct PowerBalance: Codable, Equatable {
    let percentage: Double
    let reference: PowerBalanceReferance
}

protocol PowerMeterHandler {
    var powerPublisher: AnyPublisher<Int, Never> { get }
    var pedalPowerBalancePublisher: AnyPublisher<PowerBalance, Never> { get }
    var cadencePublisher: AnyPublisher<Int, Never> { get }
}
