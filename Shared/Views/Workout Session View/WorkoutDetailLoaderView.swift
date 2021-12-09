//
//  WorkoutDetailLoaderView.swift
//  Fatigue
//
//  Created by Mats Mollestad on 16/10/2021.
//

import SwiftUI

struct WorkoutDetailLoaderView: View {
    
    let workout: Workout.Overview
    
    @State
    var detailedWorkout: Workout?
    
    @State
    var error: Error?
    
    @EnvironmentObject
    var workoutComputation: WorkoutComputationStore
    
    @EnvironmentObject
    var model: AppModel
    
    var body: some View {
        if let detailedWorkout = detailedWorkout {
            ComputeWorkoutSummaryView(workout: detailedWorkout) { summary in
                WorkoutDetailView(workout: detailedWorkout, summary: summary)
            }
        } else if let error = error {
            Text("An error occured")
            Text(error.localizedDescription)
        } else {
            ProgressView("Loading Workout...")
                .onAppear(perform: loadWorkout)
        }
    }
    
    func loadWorkout() {
        do {
            detailedWorkout = try model.workoutStore.workout(with: workout.id)
        } catch {
            self.error = error
        }
    }
}

struct WorkoutDetailLoaderView_Previews: PreviewProvider {
    static var previews: some View {
        WorkoutDetailLoaderView(workout: .init(id: .init(), duration: 50, startedAt: .init()))
    }
}
