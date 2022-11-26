//
//  WorkoutLapsView.swift
//  Fatigue
//
//  Created by Mats Mollestad on 12/02/2022.
//

import Foundation
import SwiftUI

struct WorkoutLapsView: View {
    
    let workout: Workout
    let laps: [WorkoutLap]

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                WorkoutValueView(type: .lapNumber.max, value: laps.count.formatted())
                
                WorkoutLineChart(
                    workout: workout,
                    type: .power,
                    frameKey: \.power?.value.asDouble,
                    verticalLines: laps.map(\.startedAt).filter { $0 != 0 }
                )
                
                VStack(spacing: 70) {
                    ForEach(laps) { lap in
                        WorkoutLapSummary(workout: workout, lap: lap)
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Laps")
    }
}

struct WorkoutLapsView_Previews: PreviewProvider {
    static var previews: some View {
        WorkoutLapsView(workout: .init(id: .init(), startedAt: .init(), values: [], laps: []), laps: [.preview, .preview, .preview, .preview])
    }
}
