//
//  RevolutionHandler.swift
//  Fatigue
//
//  Created by Mats Mollestad on 13/06/2021.
//

import Foundation

class RevolutionHandler {
    
    var hasRevicedValues: Bool = false
    var lastEvent: Int = 0
    var cumulativeRevolutions: Int = 0
    var rpm: Int = 0
    
    var maxEventValue: Int
    var maxRevolutionValue: Int
    
    init(maxEventValue: Int = Int(UInt16.max), maxRevolutionValue: Int = Int(UInt16.max)) {
        self.maxEventValue = maxEventValue
        self.maxRevolutionValue = maxRevolutionValue
    }
    
    func update(event: Int, revolutions: Int) -> Int {
        guard hasRevicedValues else {
            self.lastEvent = event
            self.cumulativeRevolutions = revolutions
            self.hasRevicedValues = true
            return rpm
        }
        var revolutionsSinceLastEvent = revolutions - cumulativeRevolutions
        if event < lastEvent {
            lastEvent = lastEvent - maxEventValue
        }
        if revolutionsSinceLastEvent == 0 {
            lastEvent = event
            rpm = 0
            return 0
        } else if revolutionsSinceLastEvent < 0 {
            revolutionsSinceLastEvent = revolutions + (maxRevolutionValue - cumulativeRevolutions)
        }
        cumulativeRevolutions = revolutions
        rpm = 60 * 1024 * revolutionsSinceLastEvent / (event - lastEvent)
        lastEvent = event
        return rpm
    }
}
