//
//  WorkoutDetailView.swift
//  Fatigue
//
//  Created by Mats Mollestad on 13/10/2021.
//

import Foundation
import SwiftUI

struct WorkoutDetailView: View {
    
    let workout: Workout
    let summary: Workout.Summary
    
    @State
    var result: LSCTResult?
    
    let durationFormatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute, .second]
        return formatter
    }()
    
    #if os(iOS)
    @Environment(\.horizontalSizeClass)
    var horizontalSizeClass
    #endif
    
    @EnvironmentObject
    var appModel: AppModel
    
    var columns: [GridItem] {
        #if os(iOS)
        if horizontalSizeClass == .regular {
            return [
                GridItem(.flexible()),
                GridItem(.flexible()),
            ]
        } else {
            return [
                GridItem(.flexible()),
            ]
        }
        #else
        return [
            GridItem(.flexible()),
        ]
        #endif
    }
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns) {
                
                sectionStack {
                    WorkoutValueView(
                        type: .duration,
                        value: durationFormatter.string(from: TimeInterval(workout.elapsedTime)) ?? "\(workout.elapsedTime)"
                    )
                    
                    if workout.laps.count > 0 {
                        WorkoutValueView(
                            type: .lapNumber,
                            value: "\(workout.laps.count)"
                        )
                    }
                }
                
                if let baseline = appModel.workoutStore.baseline {
                    
                    VStack(alignment: .leading) {
                        Text("LSCT")
                            .foregroundColor(Color.init(UIColor.secondaryLabel))
                            .font(.footnote)
                        
                        ComputeLsctView(workout: workout, baseline: baseline, result: $result)
                        sectionSpacer
                    }
                }
                
                if let power = summary.power {
                    
                    WorkoutLineChart(
                        workout: workout,
                        type: .power,
                        frameKey: \.power?.value.asDouble
                    )
                    
                    VStack {
                        WorkoutValueView(
                            type: .power.average,
                            value: power.average.formatted()
                        )
                        WorkoutValueView(
                            type: .power.normalized,
                            value: power.normalized.formatted()
                        )
                        WorkoutValueView(
                            type: .power.max,
                            value: power.max.formatted()
                        )
                        
                        if let balance = power.powerBalance {
                            WorkoutValueView(
                                type: .powerBalance.average,
                                value: balance.description()
                            )
                        }
                        
                        sectionSpacer
                    }
                }
                
                if let heartRate = summary.heartRate {

                    
                    WorkoutLineChart(
                        workout: workout,
                        type: .heartRate,
                        frameKey: \.heartRate?.value.asDouble
                    )
                 
                    VStack {
                        WorkoutValueView(
                            type: .heartRate.average,
                            value: "\(heartRate.average)"
                        )
                        WorkoutValueView(
                            type: .heartRate.max,
                            value: "\(heartRate.max)"
                        )
                        sectionSpacer
                    }
                    
                    ComputeDfaAlphaView(workout: workout)
                }
                
                if let cadence = summary.cadence {
                    
                    WorkoutLineChart(
                        workout: workout,
                        type: .cadence,
                        frameKey: \.cadence?.value.asDouble
                    )
                    
                    VStack {
                        WorkoutValueView(
                            type: .cadence.average,
                            value: "\(cadence.average)"
                        )
                        
                        WorkoutValueView(
                            type: .cadence.max,
                            value: "\(cadence.max)"
                        )
                        
                        sectionSpacer
                    }
                }
                
            }
            .padding()
        }
        .navigationTitle("Workout Summary")
    }
    
    var sectionSpacer: some View {
        Spacer().padding()
    }
    
    @ViewBuilder
    func sectionStack<T: View>(@ViewBuilder builder: () -> T) -> some View {
        #if os(iOS)
        if horizontalSizeClass == .regular {
            VStack {
                builder()
            }
        } else {
            HStack {
                builder()
            }
        }
        #else
        VStack {
            builder()
        }
        #endif
    }
}
