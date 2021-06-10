//
//  MeanMaximalPower.swift
//  Fatigue
//
//  Created by Mats Mollestad on 02/06/2021.
//

import Foundation

class MeanMaximalPower {
    
    struct Curve {
        
        /// The max means at a given index / second
        let means: [Int]
        
        func maxMean(at second: Int) throws -> Int {
            guard 0..<means.count ~= second else {
                return .zero
            }
            return means[second]
        }
    }
    
    func generate(powers: [Double], progress: (Double) -> Void) -> Curve {
        
        var maxMeans = Array<Double>(repeating: 0.0, count: powers.count)
        var means = Array<Double>(repeating: 0.0, count: powers.count)
        
        let numberOfComputations = Double(powers.count * powers.count) / 2
        var lastProgress: Double = 0
        for (index, power) in powers.enumerated() {
            
            for i in 0..<index {
                let j = index - i
                let averagePower = (means[j - 1] * Double(j) + power) / Double(j + 1)
                means[j] = averagePower
                
                if averagePower > maxMeans[j] {
                    maxMeans[j] = averagePower
                }
                
                let newProgress = Double(index * index / 2 + i) / numberOfComputations
                if newProgress - lastProgress > 0.01 {
                    lastProgress = newProgress
                    progress(newProgress)
                }
            }
            
            if power > maxMeans[0] {
                maxMeans[0] = power
            }
            means[0] = power
        }
        
        return Curve(means: maxMeans.map { Int($0) })
    }
}
