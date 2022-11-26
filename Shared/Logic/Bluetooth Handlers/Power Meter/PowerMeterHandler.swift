//
//  PowerMeterHandler.swift
//  Fatigue
//
//  Created by Mats Mollestad on 17/06/2021.
//

import Foundation
import Combine

extension NumberFormatter {
    public static let defaultFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.maximumFractionDigits = 3
        formatter.minimumFractionDigits = 0
        return formatter
    }()
    
    public static func maxFractionDigits(_ digits: Int) -> NumberFormatter {
        let formatter = NumberFormatter()
        formatter.maximumFractionDigits = digits
        formatter.minimumFractionDigits = 0
        return formatter
    }
}

public struct PowerBalance: Codable, Equatable {
    public let percentage: Double
    public let reference: PowerBalanceReferance
    
    public func description(formatter: NumberFormatter = .maxFractionDigits(1)) -> String {
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
