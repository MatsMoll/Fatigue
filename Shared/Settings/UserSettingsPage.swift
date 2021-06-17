//
//  UserSettingsPage.swift
//  Fatigue
//
//  Created by Mats Mollestad on 09/06/2021.
//

import SwiftUI
import Combine

#if os(iOS)
extension UIApplication {
    func endEditing() {
        sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
#endif

struct UserSettingsPage: View {
    
    static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
    
    @EnvironmentObject
    var settings: UserSettings
    
    @EnvironmentObject
    var model: AppModel
    
    var body: some View {
        Form {
            Section(header: Label("FTP", symbol: .boltFill)) {
                #if os(iOS)
                NumberField(value: $settings.ftp)
                #elseif os(OSX)
                TextField("FTP", value: $settings.ftp, formatter: NumberFormatter.defaultFormatter)
                #endif
            }
            
            Section(header: Label("RR-Interval Artifact Correction", symbol: .skew)) {
                #if os(iOS)
                NumberField($settings.artifactCorrection, keyboardType: .decimalPad)
                #elseif os(OSX)
                TextField("RR-Interval Artifact Correction", value: $settings.artifactCorrection, formatter: NumberFormatter.defaultFormatter)
                #endif
            }
            
            Section(header: Label("DFA Alpha 1 Window Size", symbol: .waveformPathEcg)) {
                #if os(iOS)
                NumberField($settings.dfaWindow)
                #elseif os(OSX)
                TextField("DFA Alpha 1 Window Size", value: $settings.dfaWindow, formatter: NumberFormatter.defaultFormatter)
                #endif
            }
            
            Section(header: Label("LSCT Baseline", symbol: .figureWalk)) {
                Picker("LSCT Baseline", selection: $settings.baselineWorkoutID) {
                    
                    Text("None Selected")
                        .tag(Optional<Workout.ID>.none)
                    
                    ForEach(model.workoutStore.workouts, id: \.id) { workout in
                        Text(Self.dateFormatter.string(from: workout.startedAt))
                            .tag(Optional<Workout.ID>.some(workout.id))
                            .id(Optional<Workout.ID>.some(workout.id))
                    }
                }
//                .pickerStyle(WheelPickerStyle())
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
