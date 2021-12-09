//
//  ContentView.swift
//  Fatigue
//
//  Created by Mats Mollestad on 14/06/2021.
//

import SwiftUI

struct ContentView: View {
    
    @EnvironmentObject var model: AppModel
    @EnvironmentObject var settings: UserSettings
    
    @StateObject private var recorder: ActivityRecorder
    @StateObject var computationStore: WorkoutComputationStore
    
    init(settings: UserSettings, manager: DeviceManager) {
        _computationStore = StateObject(wrappedValue: WorkoutComputationStore(settings: settings))
        _recorder = StateObject(wrappedValue: ActivityRecorder(settings: settings, deviceManager: manager))
    }
    
    #if os(OSX)
    @State
    var presentRecordView = false
    #endif
    
    var body: some View {
        #if os(iOS)
        TabView(selection: $model.selectedTab) {
            WorkoutListView()
                .tabItem {
                    Label("Workouts", symbol: .figureWalk)
                }
                .tag(AppTabs.history)
            
            NavigationView {
                RecordWorkoutView()
                    .task {
                        Task {
                            do {
                                try loadBaseline()
                                recorder.enableLsctDetection(workoutStore: model.workoutStore)
                            } catch {
                                print("Error loading baseline workout \(error)")
                            }
                        }
                    }
            }
            .tabItem { Label("Record", symbol: .recordCircle) }
            .tag(AppTabs.recording)
            .navigationViewStyle(.stack)
            
            NavigationView {
                UserSettingsPage()
            }
            .tabItem { Label("Settings", symbol: .gearshapeFill) }
            .tag(AppTabs.settings)
            .navigationViewStyle(.stack)
        }
        .environmentObject(model)
        .environmentObject(recorder)
        .environmentObject(computationStore)
        .onReceive(settings.$baselineWorkoutID) { workoutID in
            do {
                try loadBaseline()
            } catch {
                print("Error: \(error)")
            }
        }
        
        #elseif os(OSX)
        WorkoutListView()
            .toolbar {
                ToolbarItem(placement: ToolbarItemPlacement.automatic) {
                    Button(action: {
                        presentRecordView = true
                    }, label: {
                        Label("Record", symbol: .recordCircle)
                    })
                }
            }
            .sheet(isPresented: $presentRecordView) {
                RecordWorkoutView()
            }
            .environmentObject(model)
            .environmentObject(recorder)
        #endif
    }
    
    func loadBaseline() throws {
        var baselineID = settings.baselineWorkoutID
        if baselineID == nil {
            baselineID = model.workoutStore.workouts.first?.id
        }
        guard let baselineID = baselineID else { return }
        let baselineWorkout = try model.workoutStore.workout(with: baselineID)
        DispatchQueue.main.async {
            model.workoutStore.baseline = baselineWorkout
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(settings: .init(), manager: .init())
    }
}
