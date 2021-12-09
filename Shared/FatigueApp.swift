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
    @StateObject private var deviceManager = DeviceManager()
//    @StateObject private var bluetoothManager: BluetoothManager = .init()
    
    @StateObject var garminDeviceManager: GarminDeviceListViewModel = .init()
    
    var body: some Scene {
        WindowGroup {
            ContentView(settings: settings, manager: deviceManager)
                .environmentObject(model)
                .environmentObject(settings)
                .environmentObject(deviceManager)
                .environmentObject(garminDeviceManager)
                .onOpenURL(perform: { url in
                    let deeplink = Deeplinker(garminDeviceManager: garminDeviceManager).manage(url: url)
                    guard let deeplink = deeplink else { return }
                    if deeplink == .recorderPage {
                        model.selectedTab = .recording
                    }
                })
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
