//
//  UserSettings.swift
//  Fatigue
//
//  Created by Mats Mollestad on 09/06/2021.
//

import Foundation
import OSLog
import Combine

public class UserSettings: ObservableObject, Codable {
    
    enum CodingKeys: String, CodingKey {
        case ftp
        case artifactCorrection
        case dfaWindow
        case baselineWorkoutID
    }
    
    @Published
    var ftp: Int?
    
    @Published
    var artifactCorrection: Double?
    
    var artifactCorrectionThreshold: DFAStreamModel.Threshold {
        guard let value = artifactCorrection else { return .automatic }
        return .constant(value)
    }
    
    @Published
    var dfaWindow: TimeInterval = 120
    
    @Published
    var baselineWorkoutID: Workout.ID?
    
    var listners: [AnyCancellable] = []
    
    public init(
        ftp: Int? = nil,
        artifactCorrection: Double? = nil,
        dfaWindow: TimeInterval = 120,
        baselineWorkoutID: Workout.ID? = nil
    ) {
        self.ftp = ftp
        self.artifactCorrection = artifactCorrection
        self.dfaWindow = dfaWindow
        self.baselineWorkoutID = baselineWorkoutID
        setupListners()
    }
    
    public required init(from decoder: Decoder) throws {
        let keys = try decoder.container(keyedBy: CodingKeys.self)
        self.ftp = try keys.decodeIfPresent(Int.self, forKey: .ftp)
        self.artifactCorrection = try keys.decodeIfPresent(Double.self, forKey: .artifactCorrection)
        self.dfaWindow = try keys.decodeIfPresent(TimeInterval.self, forKey: .dfaWindow) ?? 120
        self.baselineWorkoutID = try keys.decodeIfPresent(Workout.ID.self, forKey: .baselineWorkoutID)
        setupListners()
    }
    
    public func encode(to encoder: Encoder) throws {
        var keys = encoder.container(keyedBy: CodingKeys.self)
        try keys.encode(ftp, forKey: .ftp)
        try keys.encode(artifactCorrection, forKey: .artifactCorrection)
        try keys.encode(dfaWindow, forKey: .dfaWindow)
        try keys.encode(baselineWorkoutID, forKey: .baselineWorkoutID)
    }
    
    private func setupListners() {
        $ftp
            .delay(for: 1, scheduler: DispatchQueue.global())
            .sink { [weak self] value in
                self?.saveValues()
        }
        .store(in: &listners)
        $artifactCorrection
            .delay(for: 1, scheduler: DispatchQueue.global())
            .sink { [weak self] _ in
                self?.saveValues()
        }
        .store(in: &listners)
        $dfaWindow
            .delay(for: 1, scheduler: DispatchQueue.global())
            .sink { [weak self] _ in
                self?.saveValues()
        }
        .store(in: &listners)
        $baselineWorkoutID
            .delay(for: 1, scheduler: DispatchQueue.global())
            .sink { [weak self] _ in
                self?.saveValues()
        }
        .store(in: &listners)
    }
    
    private func saveValues() {
        guard let data = try? JSONEncoder().encode(self) else { return }
        UserDefaults.standard.set(data, forKey: UserSettings.storageKey)
    }
}

extension UserSettings {
    convenience init(key: String, defaults: UserDefaults) {
        guard
            let data = defaults.data(forKey: key),
            let saved = try? Self.decoder.decode(UserSettings.self, from: data)
        else {
            self.init()
            return
        }
        self.init(
            ftp: saved.ftp,
            artifactCorrection: saved.artifactCorrection,
            dfaWindow: saved.dfaWindow,
            baselineWorkoutID: saved.baselineWorkoutID
        )
    }
}

extension UserSettings {
    static let storageKey = "userSettings"
    static let decoder = JSONDecoder()
    static let encoder = JSONEncoder()
}
