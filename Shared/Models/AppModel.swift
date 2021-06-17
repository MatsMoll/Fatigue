//
//  AppModel.swift
//  Fatigue
//
//  Created by Mats Mollestad on 11/06/2021.
//

import Foundation
import OSLog
#if os(iOS)
import UIKit
#endif

enum AppTabs: Int, Hashable {
    case history
    case recording
    case settings
}

class AppModel: ObservableObject {
    
    @Published
    var workoutStore: WorkoutStore
    
    @Published
    var recorder: ActivityRecorder
    
    @Published
    var bluetoothManager: BluetoothManager
    
    @Published
    var imports: ImportsModel
    
    #if os(iOS)
    @Published
    var selectedTab: AppTabs = .recording
    #endif
    
    let logger = Logger(subsystem: "fatigue.app.model", category: "app.model")
    
    let settingsDefaults = UserDefaults(suiteName: "fatigue.settings")!
    
    lazy var recorderCollector: ActivityRecorderCollector = {
        ActivityRecorderCollector(
            manager: self.bluetoothManager,
            settings: .init(),
            onNewFrame: { [weak self] (frame, numberOfArtifactsRemoved) in
            DispatchQueue.main.async {
                self?.recorder.record(frame: frame)
                self?.recorder.numberOfArtifactsRemoved = numberOfArtifactsRemoved
            }
        })
    }()
    
    init() {
        self.workoutStore = .init(userDefaults: .init(suiteName: "fatigue.workout.store")!)
        let manager = BluetoothManager()
        self.bluetoothManager = manager
        self.recorder = .init(workoutID: .init(), startedAt: Date())
        self.imports = .init()
        
        #if os(iOS)
        UIScrollView.appearance().keyboardDismissMode = .onDrag
        #endif
    }
    
    func importFile(_ result: Result<[URL], Error>) {
        switch result {
        case .failure(let error):
            logger.debug("Error when importing file: \(error.localizedDescription)")
        case .success(let urls):
            for url in urls {
                DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                    do {
                        let newWorkout = try Workout.importFit(url) { progress in
                            DispatchQueue.main.async {
                                self?.imports.inProgress[url] = progress
                            }
                        }
                        
                        DispatchQueue.main.async {
                            self?.workoutStore.add(newWorkout)
                        }
                    } catch {
                        self?.logger.debug("Error when importing: \(error.localizedDescription)")
                    }
                    
                    DispatchQueue.main.async {
                        self?.imports.inProgress[url] = nil
                    }
                }
            }
        }
    }
    
    func saveRecordedActivity() {
        let workout = recorder.workout
        recorderCollector.stopRecording()
        guard !workout.values.isEmpty else { return }
        workoutStore.add(workout)
        workoutStore.selectedWorkoutId = workout.id
        recorder = .init(workoutID: .init(), startedAt: .init())
        #if os(iOS)
        selectedTab = .history
        #endif
    }
}
