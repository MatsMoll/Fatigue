//
//  DataFrameLinearRegression.swift
//  Fatigue
//
//  Created by Mats Mollestad on 04/06/2021.
//

import Foundation

struct AverageStreamModel {
    
    var currentValues: [Double] = []
    var totalSum: Double = 0
    
    let maxValues: Int
    
    init(maxValues: Int) {
        self.maxValues = maxValues
    }
    
    var average: Double { totalSum / Double(currentValues.count) }
    
    mutating func add(value: Double) {
        if currentValues.count < maxValues {
            currentValues.append(value)
            totalSum += value
        } else {
            currentValues.append(value)
            totalSum += value
            totalSum -= currentValues.removeFirst()
        }
    }
}

struct DataFrameLinearRegressionError: Error {
    let reason: String
    
    static let differentAxisSize = DataFrameLinearRegressionError(reason: "Different value size on x and y axis")
    static let smallSize = DataFrameLinearRegressionError(reason: "The value size is lower then the averaging interval")
}

struct DataFrameLinearRegression {
    
    struct Result {
        let regression: LinearRegression.Result
        let values: [(Double, Double)]
        let meanSquareError: Double
    }
    
    let yValues: [Double]
    let xValues: [Double]
    
    /// The amount of values beeing averaged
    let averagingInterval: Int
    
    /// The amount of offset of the diferent values
    /// This can be used to offset values that lag behign like heart rate
    let xAxisOffset: Int
    
    /// If a data point is inclueded in the regression
    let isIncluded: ((Double, Double) -> Bool)
    
    init(yValues: [Double], xValues: [Double], averagingInterval: Int, xAxisOffset: Int, isIncluded: @escaping ((Double, Double) -> Bool) = { _,_ in true }) throws {
        guard yValues.count == xValues.count else { throw DataFrameLinearRegressionError.differentAxisSize }
        guard yValues.count > averagingInterval else { throw DataFrameLinearRegressionError.smallSize }
        guard yValues.count > averagingInterval + abs(xAxisOffset) else { throw DataFrameLinearRegressionError.smallSize }
        self.yValues = yValues
        self.xValues = xValues
        self.averagingInterval = averagingInterval
        self.xAxisOffset = xAxisOffset
        self.isIncluded = isIncluded
    }
    
    func compute() async throws -> Result {
        var yAverage = AverageStreamModel(maxValues: averagingInterval)
        var xAverage = AverageStreamModel(maxValues: averagingInterval)
        
        let absXOffset = abs(xAxisOffset)
        let endIndex = yValues.count - absXOffset
        let newXAxisOffset = max(xAxisOffset, 0)
        let yAxisOffset = max(-xAxisOffset, 0)
        
        for index in 0..<averagingInterval {
            yAverage.add(value: yValues[index + yAxisOffset])
            xAverage.add(value: xValues[index + newXAxisOffset])
        }
        
        let dataSize = endIndex - averagingInterval + 1 - absXOffset
        guard dataSize > 1 else { throw DataFrameLinearRegressionError.smallSize }
        var usedXValues: [Double] = .init(repeating: 0, count: dataSize)
        var usedYValues: [Double] = .init(repeating: 0, count: dataSize)
        
        usedXValues[0] = xAverage.average
        usedYValues[0] = yAverage.average
        
        for index in (averagingInterval + absXOffset)..<endIndex {
            yAverage.add(value: yValues[index + yAxisOffset])
            xAverage.add(value: xValues[index + newXAxisOffset])
            
            usedXValues[index - averagingInterval + 1 - absXOffset] = xAverage.average
            usedYValues[index - averagingInterval + 1 - absXOffset] = yAverage.average
        }
        
        let usedPoints = Array(zip(usedXValues, usedYValues)).filter(isIncluded)
        
        let regression = LinearRegression.compute(values: usedPoints)
        let meanSquareError = LinearRegression.meanSquareError(
            for: regression,
            values: usedPoints
        )
        return Result(
            regression: regression,
            values: usedPoints,
            meanSquareError: meanSquareError
        )
    }
}
