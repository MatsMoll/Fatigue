//
//  PowerMeterHandler.swift
//  Fatigue
//
//  Created by Mats Mollestad on 17/06/2021.
//

import Foundation
import Combine

extension NumberFormatter {
    static let defaultFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.maximumFractionDigits = 3
        formatter.minimumFractionDigits = 0
        return formatter
    }()
    
    static func maxFractionDigits(_ digits: Int) -> NumberFormatter {
        let formatter = NumberFormatter()
        formatter.maximumFractionDigits = digits
        formatter.minimumFractionDigits = 0
        return formatter
    }
}

struct PowerBalance: Codable, Equatable {
    let percentage: Double
    let reference: PowerBalanceReferance
    
    func description(formatter: NumberFormatter = .maxFractionDigits(1)) -> String {
        var leftBalance: Double = percentage
        var rightBalance: Double = 1 - percentage
        switch reference {
        case .right:
            leftBalance = 1 - percentage
            rightBalance = percentage
        default: break
        }
        return "\(formatter.string(from: .init(value: leftBalance * 100)) ?? "0")% : \(formatter.string(from: .init(value: rightBalance * 100)) ?? "0")%"
    }
}

protocol PowerMeterHandler {
    var powerPublisher: AnyPublisher<Int, Never> { get }
    var pedalPowerBalancePublisher: AnyPublisher<PowerBalance, Never> { get }
    var cadencePublisher: AnyPublisher<Int, Never> { get }
}
