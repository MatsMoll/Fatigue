//
//  SavingWorkoutView.swift
//  SavingWorkoutView
//
//  Created by Mats Mollestad on 05/09/2021.
//

import SwiftUI
import Combine
import OSLog

struct SavingWorkoutView: View {
    
    @Binding
    var shouldPresentSaving: Bool
    
    @State
    var workout: Workout?
    
    @EnvironmentObject
    var recorder: ActivityRecorder
    
    @EnvironmentObject
    var computationStore: WorkoutComputationStore
    
    @EnvironmentObject
    var appModel: AppModel
    
    var body: some View {
        if let workout = workout {
            ComputeWorkoutSummaryView(workout: workout) { summary in
                NavigationView {
                    WorkoutDetailView(workout: workout, summary: summary)
                }
                .onDisappear(perform: recorder.startObservingValues)
                .onAppear { save(workout) }
            }
        } else {
            ProgressView("Saving Workout")
                .task {
                    await computeWorkout()
                }
        }
    }
    
    func computeWorkout() async {
        recorder.stopObservingValues()
        guard let workout = recorder.stopRecording() else {
            shouldPresentSaving = false
            return
        }
        let computation = SummaryWorkoutComputation(workout: workout)
        do {
            workout.summary = try await computationStore.register(computation)
            self.workout = workout
            DispatchQueue.main.async {
                recorder.resetRecorder()
            }
        } catch {
            Logger().warning("Error: \(error.localizedDescription)")
            print("Error: \(error)")
        }
    }
    
    func save(_ workout: Workout) {
        appModel.workoutStore.add(workout)
    }
}

struct SavingWorkoutView_Previews: PreviewProvider {
    static var previews: some View {
        SavingWorkoutView(shouldPresentSaving: .constant(false))
    }
}
