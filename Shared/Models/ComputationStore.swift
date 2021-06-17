//
//  ComputationStore.swift
//  Fatigue
//
//  Created by Mats Mollestad on 14/06/2021.
//

import Foundation
import Combine

class ComputationStore: ObservableObject {
    
    @Published
    var computations: [WorkoutComputation] = []
    
    var queue: DispatchQueue = .global()
    
    var doneListners: Set<AnyCancellable> = []
    
    func computation(for id: String) -> WorkoutComputation? {
        computations.first(where: { $0.id == id })
    }
    
    func start(_ computation: WorkoutComputation, with settings: UserSettings) {
        if computations.first(where: { $0.id == computation.id }) != nil {
            return
        }
        computations.append(computation)
        queue.async { [weak self] in
            self?.doneListners.insert(
                computation.startComputation(with: settings)
                    .receive(on: DispatchQueue.main)
                    .sink { _ in
                        self?.computations.removeAll(where: { $0.id == computation.id })
                    } receiveValue: { _ in
                        self?.computations.removeAll(where: { $0.id == computation.id })
                    }
            )
        }
    }
}
