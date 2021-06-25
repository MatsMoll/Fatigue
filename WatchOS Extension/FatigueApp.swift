//
//  FatigueApp.swift
//  WatchOS Extension
//
//  Created by Mats Mollestad on 24/06/2021.
//

import SwiftUI

@main
struct FatigueApp: App {
    
    @StateObject var model: ActivityModel = .init()
    
    @SceneBuilder var body: some Scene {
        WindowGroup {
            NavigationView {
                ActivityView()
            }
            .environmentObject(model)
        }

//        WKNotificationScene(controller: NotificationController.self, category: "myCategory")
    }
}
