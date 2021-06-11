//
//  DFAAlpha1RegressionSettingsView.swift
//  Fatigue
//
//  Created by Mats Mollestad on 09/06/2021.
//

import SwiftUI

struct DFAAlpha1RegressionSettingsView: View {
    
    @Binding
    var config: DFAAlphaRegression.Config
    
    init(config: Binding<DFAAlphaRegression.Config>, showSettings: Binding<Bool>) {
        self._config = config
        self.editableConfig = config.wrappedValue
        self._showSettings = showSettings
    }
    
    @Binding
    var showSettings: Bool
    
    @State
    var editableConfig: DFAAlphaRegression.Config
    
    let numberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter
    }()
    
    var body: some View {
//        NavigationView {
            Form {
                Section(header: Text("Averaging interval")) {
                    TextField("Averaging Interval", value: $editableConfig.averageInterval, formatter: numberFormatter)
//                        .keyboardType(.numberPad)
                }
                
                Section(header: Text("DFA Alpha Offset")) {
                    TextField("DFA Alpha Offset", value: $editableConfig.dfaAlphaOffset, formatter: numberFormatter)
//                        .keyboardType(.numberPad)
                }
                
                Section(header: Text("DFA Alpha Upper Bound")) {
                    TextField("DFA Alpha Upper Bound", value: $editableConfig.dfaUpperBound, formatter: numberFormatter)
//                        .keyboardType(.numberPad)
                }
                
                Section(header: Text("DFA Alpha Lower Bound")) {
                    TextField("DFA Alpha Lower Bound", value: $editableConfig.dfaLowerBound, formatter: numberFormatter)
//                        .keyboardType(.numberPad)
                }
                
                Section {
                    Button("Save") {
                        showSettings = false
                        config = editableConfig
                    }
                    .keyboardShortcut(.defaultAction)
                    
                    #if os(OSX)
                    Button("Cancel") {
                        editableConfig = config
                        showSettings = false
                    }
                    .keyboardShortcut(.cancelAction)
                    #endif
                }
            }
            .toolbar {
                #if os(iOS)
                ToolbarItem(placement: .automatic) {
                    Button("Cancel") {
                        editableConfig = config
                        showSettings = false
                    }
                    .keyboardShortcut(.cancelAction)
                }
                #endif
            }
            .navigationTitle("DFA Alpha Regression Settings")
//        }
        .frame(minWidth: 200)
        .padding()
    }
}

struct DFAAlpha1RegressionSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        DFAAlpha1RegressionSettingsView(
            config: .constant(.default),
            showSettings: .constant(true)
        )
    }
}
