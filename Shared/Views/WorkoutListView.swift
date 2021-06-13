//
//  WorkoutListView.swift
//  Fatigue
//
//  Created by Mats Mollestad on 29/05/2021.
//

import SwiftUI
import UniformTypeIdentifiers

extension View {
    func card() -> some View {
        self
            .background(Color.white)
            .cornerRadius(3)
            .shadow(radius: 10)
    }
}

extension Array where Element == UTType {
    
    static var fit: [UTType] {
        let files = UTType.types(tag: "fit", tagClass: .filenameExtension, conformingTo: nil)
        if let fit = UTType(filenameExtension: "fit") {
            return [fit]
        } else {
            return files
        }
    }
}

struct WorkoutListView: View {
    
    @EnvironmentObject var model: AppModel
    
    @State
    var isSelectingFile: Bool = false
    
    let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .medium
        return formatter
    }()
    
    var body: some View {
        NavigationView {
            List {
                if model.imports.shouldBePresented {
                    Section(header: Label("Imports", systemImage: "square.and.arrow.down.fill")) {
                        ImportView()
                    }
                }
                Section(header: Label("Workouts", systemImage: "figure.walk")) {
                    ForEach(model.workoutStore.workouts) { workout in
                        
                        NavigationLink(
                            destination: WorkoutSessionView(viewModel: WorkoutSessionViewModel(model: model, workout: workout)),
                            tag: workout.id,
                            selection: $model.workoutStore.selectedWorkoutId
                        ) {
                            Text(dateFormatter.string(from: workout.startedAt))
                        }
                    }
                    .onDelete { indexSet in
                        model.workoutStore.deleteWorkout(indexSet: indexSet)
                    }
                }
            }
            .listStyle(SidebarListStyle())
            .navigationTitle("Workouts")
            .toolbar(content: {
                ToolbarItem(placement: ToolbarItemPlacement.primaryAction) {
                    Button(action: {
                        isSelectingFile = true
                    }, label: {
                        Label("Import", systemImage: "square.and.arrow.down")
                    })
                    .keyboardShortcut(KeyEquivalent("i"), modifiers: .command)
                }
            })
            .fileImporter(
                isPresented: $isSelectingFile,
                allowedContentTypes: .fit,
                allowsMultipleSelection: true
            ) { result in
                model.importFile(result)
            }
            .onAppear {
                model.workoutStore.loadWorkouts()
            }
        }
        .navigationViewStyle(DefaultNavigationViewStyle())
    }
}
