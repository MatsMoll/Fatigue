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
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color(UIColor.secondarySystemBackground))
            .cornerRadius(10)
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
    
    @EnvironmentObject var settings: UserSettings
    
    @State
    var isSelectingFile: Bool = false
    
    @State
    var isLoading = false
    
    let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
    
    let durationFormatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute, .second]
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
                    if isLoading {
                        ProgressView("Loading...")
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                    ForEach(model.workoutStore.workouts) { workout in
                        
                        NavigationLink(
                            destination: WorkoutDetailLoaderView(workout: workout),
                            tag: workout.id,
                            selection: $model.workoutStore.selectedWorkoutId
                        ) {
                            VStack(alignment: .leading) {
                                Text(dateFormatter.string(from: workout.startedAt))
                                    .font(.system(.footnote))
                                    .foregroundColor(.secondary)
                                
                                Text(durationFormatter.string(from: TimeInterval(workout.duration)) ?? "\(workout.duration)")
                                    .font(.system(.headline))
                            }
                        }
                    }
                    .onDelete { indexSet in
                        do {
                            try model.workoutStore.deleteWorkout(indexSet: indexSet)
                        } catch {
                            print("Error when deleting \(error.localizedDescription)")
                        }
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
            .onAppear(perform: {
                if model.workoutStore.hasLoadedFromFile { return }
                isLoading = true
                DispatchQueue.global().async {
                    let workouts = model.workoutStore.loadWorkouts()
                    
                    DispatchQueue.main.async {
                        isLoading = false
                        model.workoutStore.workouts = workouts
                        model.workoutStore.hasLoadedFromFile = true
                    }
                }
            })
        }
        .navigationViewStyle(DefaultNavigationViewStyle())
    }
}
