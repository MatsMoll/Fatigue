//
//  FatigueApp.swift
//  Shared
//
//  Created by Mats Mollestad on 29/05/2021.
//

import SwiftUI

@main
struct FatigueApp: App {
    
    @StateObject
    var workoutStore: WorkoutStore = .init()
    
    @StateObject
    var userSettings: UserSettings = .init(ftp: 280)
    
    var body: some Scene {
        WindowGroup {
            #if os(iOS)
            TabView {
                WorkoutListView(
                    store: workoutStore,
                    userSettings: userSettings
                )
                .tabItem { Label("Workouts", systemImage: "figure.walk") }
                
                NavigationView {
                    UserSettingsPage(
                        userSettings: userSettings
                    )
                }
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
            }
            #elseif os(OSX)
            WorkoutListView(
                store: workoutStore,
                userSettings: userSettings
            )
            #endif
        }
        
        #if os(OSX)
        Settings {
            UserSettingsPage(userSettings: userSettings)
                .frame(width: 350, height: 100)
        }
        #endif
    }
}
