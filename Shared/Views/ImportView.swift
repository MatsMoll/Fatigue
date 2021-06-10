//
//  ImportView.swift
//  Fatigue
//
//  Created by Mats Mollestad on 30/05/2021.
//

import SwiftUI

class ImportViewModel: ObservableObject {
    
    @Published
    var progress: [URL: Double]
    
    @Published
    var shouldBePresented: Bool = false
    
    let workoutStore: WorkoutStore
    
    init(workoutStore: WorkoutStore) {
        self.workoutStore = workoutStore
        self.progress = [:]
    }
    
    func importFile(_ result: Result<[URL], Error>) {
        switch result {
        case .failure(let error):
            print(error)
            shouldBePresented = false
        case .success(let urls):
            shouldBePresented = true
            for url in urls {
                
                DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                    
                    guard let workoutStore = self?.workoutStore else {
                        print("Self is nil")
                        return
                    }
                    do {
                        try workoutStore.importFit(url) { progress in
                            DispatchQueue.main.async {
                                self?.progress[url] = progress
                            }
                        }
                    } catch {
                        print("Error: \(error)")
                    }
                    DispatchQueue.main.async {
                        self?.progress[url] = nil
                        if self?.progress.isEmpty != false {
                            self?.shouldBePresented = false
                        }
                    }
                }
            }
        }
    }
}

struct ImportView: View {
    
    @ObservedObject
    var viewModel: ImportViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(viewModel.progress.sorted(by: { $0.value > $1.value }), id: \.key) { value in
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
        ImportView(viewModel: .init(workoutStore: .init()))
    }
}
