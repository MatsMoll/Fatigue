//
//  ImportView.swift
//  Fatigue
//
//  Created by Mats Mollestad on 30/05/2021.
//

import SwiftUI

struct ImportsModel {
    
    var inProgress: [URL: Double] = [:]
    
    var shouldBePresented: Bool { !inProgress.isEmpty }
}

struct ImportView: View {
    
    @EnvironmentObject var model: AppModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(model.imports.inProgress.sorted(by: { $0.value > $1.value }), id: \.key) { value in
                Text("Importing \(value.key.lastPathComponent)")
                    .foregroundColor(.primary)
                Text("\(Int(value.value * 100))%")
                    .foregroundColor(.secondary)
                ProgressView(value: value.value)
            }
        }
        .frame(minWidth: 200)
        .multilineTextAlignment(.center)
        .padding()
    }
}

struct ImportView_Previews: PreviewProvider {
    static var previews: some View {
        ImportView()
            .environmentObject(AppModel())
    }
}
