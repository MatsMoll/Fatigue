//
//  ComputationStore.swift
//  Fatigue
//
//  Created by Mats Mollestad on 14/06/2021.
//

import Foundation
import Combine
import OSLog

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
    
    let logger: Logger
    
    init(settings: UserSettings, logger: Logger = Logger(subsystem: "fatigue.workout-computation-store", category: "workout-computation-store")) {
        self.settings = settings
        self.logger = logger
    }
    
    func register<T: ComputationalTask>(_ computation: T) async throws -> T.Output {
        logger.info("Adding computation with id: \(computation.id)")
        guard !runningComputations.contains(computation.id) else { throw GenericError(reason: "Already registerd task") }
        runningComputations.insert(computation.id)
        logger.info("Running computation with id: \(computation.id)")
        do {
            let output = try await computation.compute(with: settings)
            runningComputations.remove(computation.id)
            logger.info("Finnshed computation with id: \(computation.id)")
            return output
        } catch {
            logger.error("Error for computation with id: \(computation.id), Error: \(error.localizedDescription)")
            runningComputations.remove(computation.id)
            throw error
        }
    }
}


