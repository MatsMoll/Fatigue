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
    @StateObject private var settings: UserSettings = .init(key: UserSettings.storageKey, defaults: .standard)
    @StateObject private var bluetoothManager: BluetoothManager = .init()
    @StateObject private var computationStore: ComputationStore = .init()
    
    var body: some Scene {
        WindowGroup {
            ContentView(settings: settings, manager: bluetoothManager)
                .environmentObject(model)
                .environmentObject(settings)
                .environmentObject(computationStore)
        }
        
        #if os(OSX)
        Settings {
            UserSettingsPage()
                .frame(width: 350, height: 400)
                .environmentObject(model)
                .environmentObject(settings)
                .environmentObject(computationStore)
        }
        #endif
    }
}
