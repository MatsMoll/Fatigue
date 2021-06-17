//
//  LinearRegression.swift
//  Fatigue
//
//  Created by Mats Mollestad on 30/05/2021.
//

import Foundation

enum LinearRegressionError: Error {
    case mismatchedValueSize(xValueCount: Int, yValueCount: Int)
}

public struct LinearRegression {
    
    public struct Result: Codable {
        // The alpha in the a + b * x equation
        public let alpha: Double
        
        // The beta in the a + b * x equation
        public let beta: Double
        
        func desciption(with formatter: NumberFormatter) -> String {
            return "\(formatter.string(from: .init(value: alpha)) ?? "") \(beta.sign == .minus ? "-" : "+") \(formatter.string(from: .init(value: abs(beta))) ?? "") * x"
        }
    }
    
    static func compute(xValues: [Double], yValues: [Double]) throws -> Result {
        guard xValues.count == yValues.count else {
            throw LinearRegressionError.mismatchedValueSize(xValueCount: xValues.count, yValueCount: yValues.count)
        }
        var xSum: Double = 0
        var xPowSum: Double = 0
        var ySum: Double = 0
        var xySum: Double = 0
        for i in 0..<xValues.count {
            xSum += xValues[i]
            xPowSum += pow(xValues[i], 2)
            ySum += yValues[i]
            xySum += yValues[i] * xValues[i]
        }
        return compute(
            dataSize: xValues.count,
            xSum: xSum,
            xPowSum: xPowSum,
            ySum: ySum,
            xySum: xySum
        )
    }
    
    static func compute(values: [(Double, Double)]) -> Result {
        var xSum: Double = 0
        var xPowSum: Double = 0
        var ySum: Double = 0
        var xySum: Double = 0
        for i in 0..<values.count {
            xSum += values[i].0
            xPowSum += pow(values[i].0, 2)
            ySum += values[i].1
            xySum += values[i].1 * values[i].0
        }
        return compute(
            dataSize: values.count,
            xSum: xSum,
            xPowSum: xPowSum,
            ySum: ySum,
            xySum: xySum
        )
    }
    
    static func compute(dataSize: Int, xSum: Double, xPowSum: Double, ySum: Double, xySum: Double) -> Result {
        let deliminator = Double(dataSize) * xPowSum - xSum * xSum
        if deliminator.isZero {
            return Result(alpha: 0, beta: 0)
        }
        return Result(
            alpha: (ySum * xPowSum - xSum * xySum) / deliminator,
            beta: (Double(dataSize) * xySum - xSum * ySum) / deliminator
        )
    }
    
    static func meanSquareError(for regResult: Result, xValues: [Double], yValues: [Double]) throws -> Double {
        guard xValues.count == yValues.count else {
            throw LinearRegressionError.mismatchedValueSize(xValueCount: xValues.count, yValueCount: yValues.count)
        }
        var errorSum: Double = 0
        for (i, xValue) in xValues.enumerated() {
            let error = regResult.beta * xValue + regResult.alpha - yValues[i]
            errorSum += error * error
        }
        return errorSum / Double(xValues.count)
    }
    
    static func meanSquareError(for regResult: Result, values: [(Double, Double)]) -> Double {
        var errorSum: Double = 0
        for (xValue, yValue) in values {
            let error = regResult.beta * xValue + regResult.alpha - yValue
            errorSum += error * error
        }
        return errorSum / Double(values.count)
    }
    
    static func meanSquareError(for regResult: Result, yValues: [Double], xValueSize: Int) -> Double {
        var errorSum: Double = 0
        for i in 0..<xValueSize {
            let error = regResult.beta * Double(i) + regResult.alpha - yValues[i]
            errorSum += error * error
        }
        return errorSum / Double(xValueSize)
    }
    
    static func meanSquareError(for regResult: Result, values: [Double]) -> Double {
        meanSquareError(for: regResult, yValues: values, xValueSize: values.count)
    }
}
