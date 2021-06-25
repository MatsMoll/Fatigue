//
//  LSCTStreamDetector.swift
//  Fatigue
//
//  Created by Mats Mollestad on 18/06/2021.
//

import Foundation

struct LSCTStage {
    
    /// The number of data frames / seconds in a stage
    let duration: Int
    
    /// The target power
    let targetPower: Double
}

struct FixedSizeArray<Element> {
    private var elements: [Element]
    private var startIndex: Int
    private var endIndex: Int
    private var maxSize: Int
    
    init(maxSize: Int, emptyValue: Element) {
        elements = Array<Element>.init(repeating: emptyValue, count: maxSize)
        self.maxSize = maxSize
        startIndex = 0
        endIndex = 0
    }
    
    subscript(_ index: Int) -> Element {
        get { elements[(startIndex + index) % maxSize] }
    }
    
    /// Adds an element to the list, while also removing the oldest element if needed
    /// - Parameter element: The element to add
    /// - Returns: The element that was removed
    @discardableResult
    mutating func add(_ element: Element) -> Element? {
        endIndex = (endIndex + 1) % maxSize
        if endIndex == startIndex {
            let oldElement = elements[startIndex]
            startIndex = (startIndex + 1) % maxSize
            elements[endIndex] = element
            return oldElement
        } else {
            elements[endIndex] = element
            return nil
        }
    }
    
    var count: Int {
        (endIndex - startIndex) % maxSize
    }
}

class LSCTStreamDetector {
    
    private var totalError: Double = 0
    var meanSquareError: Double { totalError / Double(valueCount) }
    let stages: [LSCTStage]
    
    private var values: [FixedSizeArray<Double>]
    private let totalDuration: Int
    private(set) var valueCount: Int = 0
    private let minTargetPower: Double
    
    let threshold: Double
    var isBelowThreshold: Bool { meanSquareError < threshold }
    
    init(stages: [LSCTStage], threshold: Double) {
        self.threshold = threshold
        let stageDurations = stages.map(\.duration)
        self.stages = stages
        self.values = stageDurations.map { .init(maxSize: $0, emptyValue: 0) }
        self.minTargetPower = stages.map(\.targetPower).filter({ $0 != 0 }).min() ?? 1
        totalDuration = stageDurations.reduce(0, +)
    }
    
    func add(power: Double) {
        var duration = 0
        if valueCount < totalDuration {
            valueCount += 1
            for (index, stage) in stages.enumerated() {
                duration += stage.duration
                guard valueCount <= duration else { continue }
                values[index].add(power)
                
                if stage.targetPower == 0 {
                    let fractionalDiff = pow(abs(power / minTargetPower) + 1, 2) - 1
                    totalError += fractionalDiff
                } else {
                    let fractionalDiff = pow(abs((power - stage.targetPower) / stage.targetPower) + 1, 2) - 1
                    totalError += fractionalDiff
                }
                break
            }
        } else {
            duration = totalDuration
            var addValue: Double? = power
            for (index, stage) in stages.reversed().enumerated() {
                duration -= stage.duration
                guard let value = addValue else { continue }
                let inversIndex = stages.count - 1 - index
                
                if stage.targetPower == 0 {
                    let fractionalDiff = pow(abs(value / minTargetPower) + 1, 2) - 1
                    totalError += fractionalDiff
                } else {
                    let fractionalDiff = pow(abs((value - stage.targetPower) / stage.targetPower) + 1, 2) - 1
                    totalError += fractionalDiff
                }
                addValue = values[inversIndex].add(value)
                if let popedValue = addValue {
                    if stage.targetPower == 0 {
                        let fractionalDiff = pow(abs(popedValue / minTargetPower) + 1, 2) - 1
                        totalError -= fractionalDiff
                    } else {
                        let fractionalDiff = pow(abs((popedValue - stage.targetPower) / stage.targetPower) + 1, 2) - 1
                        totalError -= fractionalDiff
                    }
                }
            }
        }
    }
}
