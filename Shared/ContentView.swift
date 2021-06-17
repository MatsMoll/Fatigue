//
//  ContentView.swift
//  Fatigue
//
//  Created by Mats Mollestad on 14/06/2021.
//

import SwiftUI

struct ContentView: View {
    
    @EnvironmentObject var model: AppModel
    
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
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
