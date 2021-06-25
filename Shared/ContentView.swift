//
//  ContentView.swift
//  Fatigue
//
//  Created by Mats Mollestad on 14/06/2021.
//

import SwiftUI

struct ContentView: View {
    
    @EnvironmentObject var model: AppModel
    
    @StateObject private var recorder: ActivityRecorderCollector
    
    init(settings: UserSettings, manager: BluetoothManager) {
        _recorder = StateObject(wrappedValue: ActivityRecorderCollector(
            manager: manager,
            settings: settings,
            activityRecorder: .init(workoutID: .init(), startedAt: .init())
        ))
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
                ActivityRecorderView()
            }
            .tabItem { Label("Record", symbol: .recordCircle) }
            .tag(AppTabs.recording)
            
            NavigationView {
                UserSettingsPage()
            }
            .tabItem { Label("Settings", symbol: .gearshapeFill) }
            .tag(AppTabs.settings)
        }
        .environmentObject(model)
        .environmentObject(recorder)
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
                ActivityRecorderView()
            }
            .environmentObject(model)
            .environmentObject(recorder)
        #endif
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(settings: .init(), manager: .init())
    }
}
