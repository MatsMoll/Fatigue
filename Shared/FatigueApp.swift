//
//  FatigueApp.swift
//  Shared
//
//  Created by Mats Mollestad on 29/05/2021.
//

import SwiftUI

@main
struct FatigueApp: App {
    
    @StateObject private var model: AppModel = .init()
    
    #if os(OSX)
    @State
    var presentRecordView = false
    #endif
    
    var body: some Scene {
        WindowGroup {
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
            #endif
        }
        
        #if os(OSX)
        Settings {
            UserSettingsPage()
                .frame(width: 350, height: 100)
                .environmentObject(model)
        }
        #endif
    }
}
