//
//  DFAAlpha1StreamModel.swift
//  Fatigue
//
//  Created by Mats Mollestad on 30/05/2021.
//

import Foundation

public enum DFAStreamModelError: Error {
    case toFewDataPoints
    case fValueIsZero
}

public class DFAStreamModel {
    
    let artifactCorrectionThreshold: Double
    
    var values: [Double] = []
    var valueAvg: Double = 0
    var valueSize: Int = 0
    var valueSum: Double = 0
    var lastValue: Double?
    
    let xValues: [Double]
    let cumXValues: [Double]
    let cumXPowValues: [Double]
    
    var cumMeanDiff: [Double] = []
    
    let uniqueScales: Int
    let scales: [Int]
    let scaleMagnitude: [Int]
    
    /// The window duration in seconds
    let windowDuration: TimeInterval
    var numberOfArtifactsRemoved: Int = 0
    
    var alpha: Double?
    
    let lockQueue = DispatchQueue(label: "dfa.stream.model")
    
    public init(
        artifactCorrectionThreshold: Double = 0.25,
        scaleDensity: Int = 30,
        lowerScaleLimit: Int = 4,
        upperScaleLimit: Int = 16,
        windowDuration: TimeInterval = 60 * 2
    ) {

        self.artifactCorrectionThreshold = artifactCorrectionThreshold
        self.windowDuration = windowDuration
        
        var scales = [Int]()
        var scaleMagnitude = [Int]()
        var uniqueScales = 0
        
        let start = log(Double(lowerScaleLimit)) / log(10)
        let end = log(Double(upperScaleLimit)) / log(10)
        let logSpacing = (end - start) / (Double(scaleDensity) - 1)
        
        // Setup scales
        for i in 0..<scaleDensity {
            let scale = Int(floor(pow(10, start + Double(i) * logSpacing)))
            if uniqueScales > 0 {
                if scales[uniqueScales - 1] == scale {
                    scaleMagnitude[uniqueScales - 1] = scaleMagnitude[uniqueScales - 1] + 1
                } else {
                    scales.append(scale)
                    scaleMagnitude.append(1)
                    uniqueScales += 1
                }
            } else {
                scales.append(scale)
                scaleMagnitude.append(1)
                uniqueScales += 1
            }
        }
        self.scales = scales
        self.scaleMagnitude = scaleMagnitude
        self.uniqueScales = uniqueScales
        
        let largesScale = scales[uniqueScales - 1]
        
        // Setting up xValues
        var xValues = [Double]()
        var cumXPowValues = [Double]()
        var cumXValues = [Double]()
        
        for i in 0..<largesScale {
            xValues.append(Double(i))
            if i > 0 {
                cumXPowValues.append(cumXPowValues[i - 1] + pow(Double(i), 2))
                cumXValues.append(cumXValues[i - 1] + Double(i))
            } else {
                cumXPowValues.append(0)
                cumXValues.append(0)
            }
        }
        self.xValues = xValues
        self.cumXValues = cumXValues
        self.cumXPowValues = cumXPowValues
    }
    
    public func add(value: Double) {
        guard let last = lastValue else {
            lastValue = value
            addValueWithoutArtifactCorrection(value)
            return
        }
        let lowerBound = last * (1 - artifactCorrectionThreshold)
        let upperBound = last * (1 + artifactCorrectionThreshold)
        
        lastValue = value
        if lowerBound <= value && value <= upperBound {
            addValueWithoutArtifactCorrection(value)
        } else {
            numberOfArtifactsRemoved += 1
        }
    }
    
    func addValueWithoutArtifactCorrection(_ newValue: Double) {
        if valueSum > windowDuration {
            valueSum += newValue
            values.append(newValue)
            valueSize += 1;
            while valueSum >= windowDuration && values.count > 1 {
                valueSum -= values[0]
                values.remove(at: 0)
                valueSize -= 1
                let oldestMeanDiff = cumMeanDiff[0]
                let newAvg = Double(valueSum) / Double(valueSize)
                let avgDiff = newAvg - valueAvg
                valueAvg = newAvg
                for i in 0..<valueSize {
                    cumMeanDiff[i] -= avgDiff * Double(i) + oldestMeanDiff
                }
                cumMeanDiff.remove(at: 0)
            }
            cumMeanDiff.append(0)
        } else {
            valueSum += newValue
            values.append(newValue)
            let newAvg = Double(valueSum) / Double(valueSize + 1)
            let avgDiff = valueAvg - newAvg
            valueAvg = newAvg
            for i in 0..<valueSize {
                cumMeanDiff[i] += avgDiff * Double(i + 1)
            }
            cumMeanDiff.append(0)
            valueSize += 1;
        }
    }
    
    public func compute() throws -> LinearRegression.Result {
        guard valueSize > 2 else { throw DFAStreamModelError.toFewDataPoints }
        
        // Optimizing the linear regression
        var fSum: Double = 0
        var scalaSum: Double = 0
        var scalaPowSum: Double = 0
        var scalaFSum: Double = 0
        var fValueSize: Int = 0
        var linRegValues = [Double].init(repeating: 0, count: scales[uniqueScales - 1])
        
        for i in 0..<uniqueScales {
            
            let shapeX = scales[i]
            if shapeX > valueSize { break }
            let shapeY: Int = Int(floor(Double(valueSize) / Double(shapeX)))
            var upperBound = shapeX * shapeY
            if upperBound > valueSize {
                upperBound = upperBound - shapeX
            }
            let lowerBound = valueSize - upperBound
            
            var rmsSum: Double = 0
            
            /// A variable to optimize performance, and not repeate equal work
            let multiplier: Double = lowerBound == 0 ? 2 : 1
            
            for j in 0..<shapeY {
                
                var ySum: Double = 0
                var xySum: Double = 0
                
                for z in 0..<shapeX {
                    let valueIndex = j * shapeX + z
                    ySum += cumMeanDiff[valueIndex]
                    xySum += cumMeanDiff[valueIndex] * xValues[z]
                    linRegValues[z] = cumMeanDiff[valueIndex]
                }
                
                let regResult = LinearRegression.compute(
                    dataSize: shapeX,
                    xSum: cumXValues[shapeX - 1],
                    xPowSum: cumXPowValues[shapeX - 1],
                    ySum: ySum,
                    xySum: xySum
                )
                let meanError = LinearRegression.meanSquareError(
                    for: regResult,
                    yValues: linRegValues,
                    xValueSize: shapeX
                )
                rmsSum += meanError * multiplier
            }
            
            if multiplier == 1 {
                // Only run if lower bound is other then 0
                // Otherwise will this computation be in the first loop
                for j in 0..<shapeY {
                    
                    var ySum: Double = 0
                    var xySum: Double = 0
                    
                    for z in 0..<shapeX {
                        let valueIndex = j * shapeX + z + lowerBound
                        ySum += cumMeanDiff[valueIndex]
                        xySum += cumMeanDiff[valueIndex] * xValues[z]
                        linRegValues[z] = cumMeanDiff[valueIndex]
                    }
                    
                    let regResult = LinearRegression.compute(
                        dataSize: shapeX,
                        xSum: cumXValues[shapeX - 1],
                        xPowSum: cumXPowValues[shapeX - 1],
                        ySum: ySum,
                        xySum: xySum
                    )
                    let meanError = LinearRegression.meanSquareError(
                        for: regResult,
                        yValues: linRegValues,
                        xValueSize: shapeX
                    )
                    rmsSum += meanError
                }
            }
            
            let fPreValue = sqrt(1 / Double(shapeY * 2) * rmsSum)
            let fValue: Double!
            if fPreValue.isZero {
                fValue = 0
            } else {
                fValue = (log(fPreValue) / log(2)) * Double(scaleMagnitude[i])
            }
            let logScala = log(Double(scales[i])) / log(2)
            fSum += fValue
            scalaSum += logScala * Double(scaleMagnitude[i])
            scalaPowSum += pow(logScala, 2) * Double(scaleMagnitude[i])
            scalaFSum += fValue * logScala
            fValueSize += scaleMagnitude[i]
        }
        if fSum.isZero {
            throw DFAStreamModelError.fValueIsZero
        }
        
        
        return LinearRegression.compute(
            dataSize: fValueSize,
            xSum: scalaSum,
            xPowSum: scalaPowSum,
            ySum: fSum,
            xySum: scalaFSum
        )
    }
}
