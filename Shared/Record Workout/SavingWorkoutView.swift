//
//  SavingWorkoutView.swift
//  SavingWorkoutView
//
//  Created by Mats Mollestad on 05/09/2021.
//

import SwiftUI
import Combine

struct SavingWorkoutView: View {
    
    class ViewModel: ObservableObject {
        
        @Published
        var workout: Workout?
        
        var onCompleteListner: AnyCancellable?
        
        func register(_ workout: Workout, in store: WorkoutComputationStore) {
            self.workout = workout
            let summaryComputation = SummaryWorkoutComputation(workout: workout)
            let id = summaryComputation.id
            onCompleteListner = store.onComplete
                .filter { $0.id == id }
                .sink(receiveCompletion: completed, receiveValue: recived)
            store.register(summaryComputation)
        }
        
        func recived(computation: WorkoutComputationStore.CompletedComputation) {
            self.workout = computation.workout
        }
        
        func completed(_ value: Subscribers.Completion<WorkoutComputationStore.ComputationError>) {
            print("Error")
        }
    }
    
    @Binding
    var shouldPresentSaving: Bool
    
    @ObservedObject
    var viewModel: ViewModel
    
    @EnvironmentObject
    var recoder: ActivityRecorder
    
    @EnvironmentObject
    var computationStore: WorkoutComputationStore
    
    var body: some View {
        if let summary = viewModel.workout?.summary {
            VStack {
                if let power = summary.power {
                    HStack {
                        Text("Power")
                        Text("\(power.average)")
                    }
                }
                if let power = summary.heartRate {
                    HStack {
                        Text("Heart Rate")
                        Text("\(power.average)")
                    }
                }
                if let power = summary.cadence {
                    HStack {
                        Text("Cadence")
                        Text("\(power.average)")
                    }
                }
            }
        } else {
            ProgressView("Saving Workout")
                .onAppear(perform: computeWorkout)
        }
    }
    
    func computeWorkout() {
        guard let workout = recoder.stopRecording() else {
            shouldPresentSaving = false
            return
        }
        
        viewModel.register(workout, in: computationStore)
    }
}

struct SavingWorkoutView_Previews: PreviewProvider {
    static var previews: some View {
        SavingWorkoutView(shouldPresentSaving: .constant(false), viewModel: .init())
    }
}
