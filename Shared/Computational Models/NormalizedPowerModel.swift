//
//  NormalizedPowerModel.swift
//  Fatigue
//
//  Created by Mats Mollestad on 11/06/2021.
//

import Foundation

struct NormalizedPowerModel {
    
    static func compute(values: [Double]) -> Int {
        
        var averageModel = AverageStreamModel(maxValues: 30)
        
        let numberOfRolingAverages = values.count - 29
        guard numberOfRolingAverages > 0 else { return 0 }
        
        for index in 0..<29 {
            averageModel.add(value: pow(values[index], 4))
        }
        
        var averageSum: Double = 0
        for index in 29...numberOfRolingAverages {
            averageModel.add(value: pow(values[index], 4))
            averageSum += averageModel.average
        }
        
        return Int(pow(averageSum / Double(numberOfRolingAverages), 0.25)
                    .rounded())
    }
}