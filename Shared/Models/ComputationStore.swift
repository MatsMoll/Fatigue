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
    var computations: [String: WorkoutComputation] = [:]
    
    var queue: DispatchQueue = .init(label: "Fatigue.ComputationStore", qos: .background)
    
    func computation(for id: String) -> WorkoutComputation? {
        computations[id]
    }
    
    func start(_ computation: WorkoutComputation, with settings: UserSettings) {
        if computations[computation.id] != nil {
            return
        }
        
        computations[computation.id] = computation
        queue.async { [weak self] in
            computation.startComputation(with: settings)
            DispatchQueue.main.async {
                self?.computations[computation.id] = nil
            }
        }
    }
}

class WorkoutComputationStore: ObservableObject {
    
    struct ComputationError: Error {
        let id: String
        let error: Error
    }
    
    struct CompletedComputation {
        let id: String
        let workout: Workout
    }
    
    let settings: UserSettings
    
    var runningComputations = Set<String>()
    var progressListners: [String : AnyPublisher<Double, Never>] = [:]
    var onComplete: AnyPublisher<CompletedComputation, ComputationError> { onCompleteSubject.eraseToAnyPublisher() }
    private let onCompleteSubject = PassthroughSubject<CompletedComputation, ComputationError>()
    
    init(settings: UserSettings) {
        self.settings = settings
    }
    
    func register<T: ComputationalTask>(_ computation: T) {
        do {
            guard !runningComputations.contains(computation.id) else { return }
            runningComputations.insert(computation.id)
            let output = try computation.compute(with: settings)
            var workout = computation.workout
            workout[keyPath: computation.storeIn] = output
            runningComputations.remove(computation.id)
            onCompleteSubject.send(CompletedComputation(id: computation.id, workout: workout))
            onCompleteSubject.send(completion: .finished)
        } catch {
            runningComputations.remove(computation.id)
            onCompleteSubject.send(completion: .failure(.init(id: computation.id, error: error)))
        }
    }
}
