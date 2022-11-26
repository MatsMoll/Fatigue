//
//  ComputeDfaAlphaView.swift
//  Fatigue
//
//  Created by Mats Mollestad on 13/11/2021.
//

import SwiftUI

struct ComputeDfaAlphaView: View {
    
    let workout: Workout
    
    @State
    var isComputed: Bool = false
    
    @State
    var progress: Double = 0
    
    @State
    var heartRateRegression: DFAAlphaRegression?
    
    @State
    var powerRegression: DFAAlphaRegression?
    
    @EnvironmentObject
    var store: WorkoutComputationStore
    
    @EnvironmentObject
    var appModel: AppModel
    
    let computation: DFAComputation
    
    init(workout: Workout) {
        self.workout = workout
        self.computation = DFAComputation(workout: workout)
    }
    
    var body: some View {
        if let dfaAlpha1 = workout.summary?.heartRate?.dfaAlpha {
            
            WorkoutLineChart(
                workout: workout,
                type: .dfaAlpha1,
                frameKey: \.heartRate?.dfaAlpha1
            )
            
            VStack {
                WorkoutDfaSummaryView(dfaAlpha: dfaAlpha1)
                
                Spacer().frame(height: 5)
                
                ComputeDfaRegressionView(
                    workout: workout,
                    regression: $heartRateRegression,
                    too: \.heartRate?.value,
                    valueType: .heartRate
                )
                .frame(maxWidth: .infinity)
                
                Spacer().frame(height: 5)
                
                if workout.hasPower {
                 
                    ComputeDfaRegressionView(
                        workout: workout,
                        regression: $powerRegression,
                        too: \.power?.value,
                        valueType: .power
                    )
                    .frame(maxWidth: .infinity)
                    
                    Spacer().frame(height: 5)
                }
            }
        } else {
            ProgressView("Computing DFA...", value: progress)
                .task {
                    await computeDfa()
                }
                .onReceive(computation.onProgressPublisher.receive(on: DispatchQueue.main)) { progress in
                    self.progress = progress
                }
        }
    }
    
    func computeDfa() async {
        do {
            let dfaValues = try await store.register(computation)
            
            guard dfaValues.count == workout.frames.count else {
                throw GenericError(reason: "Mismatch in amount of values")
            }
            let newFrames = zip(workout.frames, dfaValues).map { (frame: WorkoutFrame, dfaValue: Double) -> WorkoutFrame in
                guard let heartRate = frame.heartRate else { return frame }
                return frame.update(with: .init(
                    timestamp: frame.timestamp,
                    power: nil,
                    heartRate: .init(
                        value: heartRate.value,
                        rrIntervals: heartRate.rrIntervals,
                        dfaAlpha1: dfaValue
                    ),
                    cadence: nil
                ))
            }
            workout.frames = newFrames
            let summary = SummaryWorkoutComputation(workout: workout)
            workout.summary = try await store.register(summary)
            save(workout)
            DispatchQueue.main.async {
                isComputed = true
            }
        } catch {
            print("Error: \(error)")
        }
    }
    
    func save(_ workout: Workout) {
        do {
            try appModel.workoutStore.update(workout: workout)
        } catch {
            print("Error: \(error.localizedDescription)")
        }
    }
}

struct WorkoutDfaSummaryView: View {
    
    let dfaAlpha: Workout.DFAAlphaSummary
    
    var body: some View {
        LazyVGrid(columns: .defaultGrid()) {
            WorkoutValueView(
                type: .dfaAlpha1.average,
                value: dfaAlpha.average.formatted(with: .defaultFormatter)
            )
            
            WorkoutValueView(
                type: .dfaAlpha1.min,
                value: dfaAlpha.min.formatted(with: .defaultFormatter)
            )
        }
    }
}

struct ComputeDfaAlphaView_Previews: PreviewProvider {
    static var previews: some View {
        ComputeDfaAlphaView(workout: .init(id: .init(), startedAt: .init(), values: [], laps: []))
    }
}
