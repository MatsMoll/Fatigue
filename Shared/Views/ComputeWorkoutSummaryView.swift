//
//  ComputeWorkoutSummaryView.swift
//  Fatigue
//
//  Created by Mats Mollestad on 17/10/2021.
//

import SwiftUI
import Combine
import OSLog

struct ComputeWorkoutSummaryView<B: View>: View {
    
    let workout: Workout
    
    let bodyBuilder: ((Workout.Summary) -> B)
    
    @State
    var summary: Workout.Summary?
    
    @EnvironmentObject
    var store: WorkoutComputationStore
    
    @EnvironmentObject
    var appModel: AppModel
    
    init(workout: Workout, body: @escaping (Workout.Summary) -> B) {
        self.workout = workout
        self.bodyBuilder = body
        self._summary = State(initialValue: workout.summary)
    }
    
    var body: some View {
        if let summary = summary {
            bodyBuilder(summary)
        } else {
            ProgressView("Computing Summary...")
                .task {
                    await computeSummary()
                }
                .onDisappear(perform: saveWorkout)
        }
    }
    
    func computeSummary() async {
        do {
            let computation = SummaryWorkoutComputation(workout: workout)
            let summary = try await store.register(computation)
            self.workout.summary = summary
            // Refreshing
            self.summary = summary
        } catch {
            print("Error: \(error)")
        }
    }
    
    func saveWorkout() {
        do {
            try appModel.workoutStore.update(workout: workout)
        } catch {
            print("Error: \(error.localizedDescription)")
        }
    }
}

struct ComputeWorkoutSummaryView_Previews: PreviewProvider {
    static var previews: some View {
        ComputeWorkoutSummaryView(workout: .init(id: .init(), startedAt: .init(), values: [], laps: [])) { _ in
            Text("dd")
        }
    }
}
