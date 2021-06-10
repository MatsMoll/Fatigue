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
    
    init(store: WorkoutStore, userSettings: UserSettings) {
        self.store = store
        self.userSettings = userSettings
        self.importViewModel = ImportViewModel(workoutStore: store)
    }
    
    @ObservedObject
    var store: WorkoutStore
    
    let userSettings: UserSettings
    
    @ObservedObject
    var importViewModel: ImportViewModel
    
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
                if importViewModel.shouldBePresented {
                    Section(header: Label("Imports", systemImage: "square.and.arrow.down.fill")) {
                        ImportView(viewModel: importViewModel)
                    }
                }
                Section(header: Label("Workouts", systemImage: "figure.walk")) {
                    ForEach(store.workouts) { (workoutModel: WorkoutSessionViewModel) in
                        NavigationLink(
                            destination: WorkoutSessionView(viewModel: workoutModel, userSetting: userSettings),
                            label: {
                                VStack(content: {
                                    Text(dateFormatter.string(from: workoutModel.workout.startedAt))
                                })
                            })
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
                importViewModel.importFile(result)
            }
        }
        .navigationViewStyle(DefaultNavigationViewStyle())
    }
}
