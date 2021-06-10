//
//  UserSettingsPage.swift
//  Fatigue
//
//  Created by Mats Mollestad on 09/06/2021.
//

import SwiftUI
import Combine

struct UserSettingsPage: View {
    
    @ObservedObject
    var userSettings: UserSettings
    
    let numberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter
    }()
    
    init(userSettings: UserSettings) {
        self.userSettings = userSettings
    }
    
    var body: some View {
        Form {
            Section(header: Label("FTP", systemImage: "bolt.fill")) {
                TextField("FTP", value: $userSettings.ftp, formatter: numberFormatter)
//                        .keyboardType(.numberPad)
            }
        }
        .navigationTitle("Settings")
        .padding()
    }
}

struct UserSettingsPage_Previews: PreviewProvider {
    static var previews: some View {
        UserSettingsPage(userSettings: .init(ftp: 280))
    }
}
