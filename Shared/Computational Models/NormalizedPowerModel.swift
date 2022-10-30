//
//  NormalizedPowerModel.swift
//  Fatigue
//
//  Created by Mats Mollestad on 11/06/2021.
//

import Foundation

struct NormalizedPowerModel {
    
    static func compute(values: [Double]) -> Int {
        
        let offset = 29
        var averageModel = AverageStreamModel(maxValues: offset + 1)
        
        let numberOfRolingAverages = values.count - offset
        guard numberOfRolingAverages > 0 else { return 0 }
        
        for index in 0..<offset {
            averageModel.add(value: values[index])
        }
        
        var averageSum: Double = 0
        for index in 0..<numberOfRolingAverages {
            averageModel.add(value: values[index + offset])
            averageSum += pow(averageModel.average, 4)
        }
        
        return Int(pow(averageSum / Double(numberOfRolingAverages), 0.25)
                    .rounded())
    }
}
