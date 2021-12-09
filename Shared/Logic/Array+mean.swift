//
//  Array+mean.swift
//  Array+mean
//
//  Created by Mats Mollestad on 04/09/2021.
//

import Foundation

extension Array where Element == Double {
    func mean() -> Double {
        guard !isEmpty else { return .nan }
        var sum: Double = 0
        for value in self {
            sum += value
        }
        return sum / Double(self.count)
    }
    
    func meanWithoutZeros() -> Double {
        var sum: Double = 0
        var count: Double = 0
        for value in self {
            if value != 0 {
                sum += value
                count += 1
            }
        }
        guard count != 0 else { return .nan }
        return sum / count
    }
}

extension Array where Element == Int {
    func mean() -> Double {
        guard !isEmpty else { return .nan }
        var sum: Int = 0
        for value in self {
            sum += value
        }
        return Double(sum) / Double(self.count)
    }
    
    func meanWithoutZeros() -> Double {
        var sum = 0
        var count: Double = 0
        for value in self {
            if value != 0 {
                sum += value
                count += 1
            }
        }
        guard count != 0 else { return .nan }
        return Double(sum) / count
    }
}
