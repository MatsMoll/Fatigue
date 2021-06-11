//
//  UserSettingsPage.swift
//  Fatigue
//
//  Created by Mats Mollestad on 09/06/2021.
//

import SwiftUI
import Combine

struct UserSettingsPage: View {
    
    @EnvironmentObject var model: AppModel
    
    let numberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter
    }()
    
    var body: some View {
        Form {
            Section(header: Label("FTP", symbol: .boltFill)) {
                TextField("FTP", value: $model.settings.ftp, formatter: numberFormatter)
                    .keyboardType(.numberPad)
            }
            
            Section(header: Label("Artifact Correction", symbol: .skew)) {
                TextField("Artifact Correction", value: $model.settings.artifactCorrection, formatter: numberFormatter)
                    .keyboardType(.numberPad)
            }
            
            Section(header: Label("DFA Alpha 1 Window Size", symbol: .waveformPathEcg)) {
                TextField("DFA Alpha 1 Window Size", value: $model.settings.dfaWindow, formatter: numberFormatter)
                    .keyboardType(.numberPad)
            }
        }
        .navigationTitle("Settings")
    }
}

struct UserSettingsPage_Previews: PreviewProvider {
    static var previews: some View {
        UserSettingsPage()
            .environmentObject(AppModel())
    }
}
