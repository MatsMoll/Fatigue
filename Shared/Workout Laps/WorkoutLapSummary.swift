//
//  WorkoutLapSummary.swift
//  Fatigue
//
//  Created by Mats Mollestad on 12/02/2022.
//

import SwiftUI

struct WorkoutLapSummary: View {
    
    let workout: Workout
    let lap: WorkoutLap
    
    var body: some View {
        VStack {
            WorkoutValueView(type: .lapNumber, value: lap.lapNumber.formatted())
            WorkoutValueView(type: .duration, value: lap.duration.formattedDuration)
            
            if let heartRate = lap.heartRate {
                Spacer().padding(3)
                HeartRateSummaryView(heartRate: heartRate)
                
                if let dfaAlpha = heartRate.dfaAlpha {
                    Spacer().padding(3)
                    WorkoutDfaSummaryView(dfaAlpha: dfaAlpha)
                }
            }
            if let power = lap.power {
                Spacer().padding(3)
                WorkoutPowerSummaryView(power: power)
            }
            if let cadence = lap.cadence {
                Spacer().padding(3)
                WorkoutCadenceSummaryView(cadence: cadence)
            }
        }
    }
}

extension Int {
    var formattedDuration: String {
        let now = Date()
        return (now..<Date(timeInterval: Double(self), since: now)).formatted(.timeDuration)
    }
}


extension WorkoutLap {
    static var preview: WorkoutLap {
        WorkoutLap(lapNumber: 3, startedAt: 90, duration: 180, summary: .preview)
    }
}

struct WorkoutLapSummary_Previews: PreviewProvider {
    static var previews: some View {
        ScrollView {
            WorkoutLapSummary(
                workout: .init(id: .init(), startedAt: .init(), values: [], laps: []),
                lap: .preview
            ).padding()
        }
    }
}
