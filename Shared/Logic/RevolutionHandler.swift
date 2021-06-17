//
//  RevolutionHandler.swift
//  Fatigue
//
//  Created by Mats Mollestad on 13/06/2021.
//

import Foundation

class RevolutionHandler {
    
    var hasRevicedValues: Bool = false
    // The last event converted into seconds
    var lastEvent: TimeInterval = 0
    var cumulativeRevolutions: Int = 0
    var rpm: Int = 0
    
    var maxEventValue: TimeInterval
    var maxRevolutionValue: Int
    
    init(maxEventValue: TimeInterval, maxRevolutionValue: Int) {
        self.maxEventValue = maxEventValue
        self.maxRevolutionValue = maxRevolutionValue
    }
    
    func update(event: TimeInterval, revolutions: Int) -> Int {
        guard hasRevicedValues else {
            self.lastEvent = event
            self.cumulativeRevolutions = revolutions
            self.hasRevicedValues = true
            return rpm
        }
        var revolutionsSinceLastEvent = revolutions - cumulativeRevolutions
        var eventDuration = event - lastEvent
        
        if eventDuration < 0 {
            eventDuration = eventDuration + maxEventValue
        }
        if revolutionsSinceLastEvent == 0 {
            lastEvent = event
            rpm = 0
            return 0
        } else if revolutionsSinceLastEvent < 0 {
            revolutionsSinceLastEvent = revolutionsSinceLastEvent + maxRevolutionValue
        }
        cumulativeRevolutions = revolutions
        rpm = Int(60 * Double(revolutionsSinceLastEvent) / eventDuration)
        lastEvent = event
        return rpm
    }
}
