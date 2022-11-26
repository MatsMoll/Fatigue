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
    
    @State
    var laps: [WorkoutLap] = []
    
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
    
    @EnvironmentObject
    var settings: UserSettings
    
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
                
                if !laps.isEmpty {
                    NavigationLink("View Lap Details") {
                        WorkoutLapsView(workout: workout, laps: laps)
                    }
                    .foregroundColor(Color.primary)
                    .background(Color.background)
                    .cornerRadius(10)
                }
                
                if let baseline = appModel.workoutStore.baseline {
                    
                    VStack(alignment: .leading) {
                        Text("LSCT")
                            .foregroundColor(.secondary)
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
                    
                    WorkoutPowerSummaryView(power: power)
                    sectionSpacer
                }
                
                if let heartRate = summary.heartRate {

                    
                    WorkoutLineChart(
                        workout: workout,
                        type: .heartRate,
                        frameKey: \.heartRate?.value.asDouble
                    )
                 
                    HeartRateSummaryView(heartRate: heartRate)
                    sectionSpacer
                    
                    ComputeDfaAlphaView(workout: workout)
                }
                
                if let cadence = summary.cadence {
                    
                    WorkoutLineChart(
                        workout: workout,
                        type: .cadence,
                        frameKey: \.cadence?.value.asDouble
                    )
                    
                    WorkoutCadenceSummaryView(cadence: cadence)
                    sectionSpacer
                }
                
            }
            .padding()
        }
        .navigationTitle("Workout Summary")
        .task {
            do {
                if workout.laps.count > 1 {
                    laps = try await ComputeWorkoutLapsSummaries(workout: workout, laps: workout.laps).compute(with: settings)
                } else {
                    laps = try await ComputeWorkoutLaps(workout: workout).compute(with: settings)
                }
            } catch {
                print("Error: \(error.localizedDescription)")
            }
        }
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

extension Array where Element == GridItem {
    
    static func defaultGrid(isWide: Bool = false) -> [GridItem] {
        
        if isWide {
            return [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible()),
            ]
        } else {
            return [
                GridItem(.flexible()),
                GridItem(.flexible()),
            ]
        }
    }
}

struct WorkoutCadenceSummaryView: View {
    
    let cadence: Workout.CadenceSummary
    
    var body: some View {
        LazyVGrid(columns: .defaultGrid()) {
            WorkoutValueView(
                type: .cadence.average,
                value: "\(cadence.average)"
            )
            
            WorkoutValueView(
                type: .cadence.max,
                value: "\(cadence.max)"
            )
        }
    }
}

struct WorkoutPowerSummaryView: View {
    
    let power: Workout.PowerSummary
    
    var body: some View {
        LazyVGrid(columns: .defaultGrid()) {
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
        }
    }
}

struct HeartRateSummaryView: View {
    
    let heartRate: Workout.HeartRateSummary
    
    var body: some View {
        LazyVGrid(columns: .defaultGrid()) {
            WorkoutValueView(
                type: .heartRate.average,
                value: "\(heartRate.average)"
            )
            WorkoutValueView(
                type: .heartRate.max,
                value: "\(heartRate.max)"
            )
        }
    }
}
