//
//  ComputeLsctView.swift
//  Fatigue
//
//  Created by Mats Mollestad on 17/10/2021.
//

import SwiftUI

struct ComputeLsctView: View {
    
    static let timeFormatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .positional
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.zeroFormattingBehavior = .dropLeading
        return formatter
    }()
    
    static let numberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 0
        return formatter
    }()

    
    let workout: Workout
    let baseline: Workout
    
    @EnvironmentObject
    var computationStore: WorkoutComputationStore
    
    @EnvironmentObject
    var settings: UserSettings
    
    @Binding
    var result: LSCTResult?
    
    @State
    var error: Error?
    
    var body: some View {
        if let error = error {
            VStack {
                Text("Ups! An error occured")
                    .font(.headline)
                
                Text(error.localizedDescription)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .card()
        } else if let result = result {
            VStack {
                LSCTResultView(lsctResult: .init(lsctResult: result))
                
                NavigationLink("More details") {
                    LSCTResultDetailView(
                        baseline: baseline,
                        workout: workout,
                        result: result
                    )
                }
                .padding()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .card()
        } else {
            ProgressView("Computing LSCT...")
                .card()
                .task {
                    do {
                        let computation = LSCTResultComputation(workout: workout, baseline: baseline)
                        result = try await computationStore.register(computation)
                    } catch {
                        self.error = error
                    }
                }
        }
    }
}

struct ComputeLsctView_Previews: PreviewProvider {
    static var previews: some View {
        ComputeLsctView(
            workout: .init(id: .init(), startedAt: .init(), values: [], laps: []),
            baseline: .init(id: .init(), startedAt: .init(), values: [], laps: []),
            result: .constant(nil)
        )
    }
}
