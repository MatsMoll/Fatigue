//
//  WorkoutSessionViewModel.swift
//  Fatigue
//
//  Created by Mats Mollestad on 04/06/2021.
//

import Foundation
import Combine
import Charts
import SwiftUI

class WorkoutSessionViewModel: ObservableObject {
    
    enum State<T> {
        case unavailable
        case computing(progress: Double)
        case computed(T)
    }
    
    let model: AppModel
    
    var workout: Workout
    
    @Published var meanMaximumPower: LoadingState<MeanMaximalPower.Curve> = .idle
    
    @Published var dfaRegression: LoadingState<DFAAlphaRegression> = .idle
    
    @Published var lsctDetection: LoadingState<LSCTDetector.Detection> = .idle
    
    @Published var dfaAlphaComputation: LoadingState<Void> = .idle
    
    
    @Published var dfaAlphaValues: [Double] = []
    
    @Published var heartRateData: [Double] = []
    
    @Published var powerData: [Double] = []
    
    @Published var cadenceData: [Double] = []
    
    let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .medium
        return formatter
    }()
    
    let dateComponentFormatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute, .second]
        return formatter
    }()
    
    var startedAt: String {
        dateFormatter.string(from: workout.startedAt)
    }
    
    var duration: String {
        dateComponentFormatter.string(from: Double(workout.elapsedTime)) ?? "--"
    }
    
    private var lsctDetectorProgressPublisher: AnyCancellable?
    private var dfaRegressionConfigDidUpdate: AnyCancellable?
    
    init(model: AppModel, workout: Workout) {
        self.model = model
        self.workout = workout
        loadWorkout()
    }
    
    func loadWorkout() {
        let valuesCount = workout.values.count
        
        var dfaValues = [Double].init(repeating: 0, count: valuesCount)
        var heartRateValues = [Double].init(repeating: 0, count: valuesCount)
        var powerValues = [Double].init(repeating: 0, count: valuesCount)
        var cadenceData = [Double].init(repeating: 0, count: valuesCount)
        
        for (index, frames) in workout.values.enumerated() {
            dfaValues[index] = frames.dfaAlpha1 ?? 0
            heartRateValues[index] = Double(frames.heartRate ?? 0)
            powerValues[index] = Double(frames.power ?? 0)
            cadenceData[index] = Double(frames.cadence ?? 0)
        }
        
        if workout.hasDFAValues {
            self.dfaAlphaValues = dfaValues
            self.dfaAlphaComputation = .loaded(())
        }
        if workout.heartRateSummary != nil {
            self.heartRateData = heartRateValues
        }
        if workout.powerSummary != nil {
            self.powerData = powerValues
        }
        if workout.cadenceSummary != nil {
            self.cadenceData = cadenceData
        }
        if let curve = workout.powerCurve {
            self.meanMaximumPower = .loaded(curve)
        }
    }
    
    func workoutChartData(maxDataPoints: Int) -> LineChartData {
        LineChartData(
            dataSets: [
                LineChartDataSet.dataSet(values: powerData, maxDataPoints: maxDataPoints, label: "Power", color: .blue),
                LineChartDataSet.dataSet(values: heartRateData, maxDataPoints: maxDataPoints, label: "Heart Rate", color: .red),
                LineChartDataSet.dataSet(values: cadenceData, maxDataPoints: maxDataPoints, label: "Cadence", color: .orange),
            ]
        )
    }
    
    func dfaAlpha(maxDataPoints: Int) -> LineChartData {
        LineChartData(
            dataSet: LineChartDataSet.dataSet(
                values: dfaAlphaValues,
                maxDataPoints: maxDataPoints,
                label: "DFA Alpha 1",
                color: .purple
            )
        )
    }
    
    func computeDfaAlpha1() {
        guard case LoadingState.idle = dfaAlphaComputation else { return }
        if workout.hasDFAValues { return }
        
        dfaAlphaComputation = .loading(progress: 0)
        let artifactCorrectionThreshold = model.settings.artifactCorrection
        let strongValues = workout.values
        let workoutID = workout.id
        DispatchQueue.global().async { [weak self] in
            let numberOfValues = Double(strongValues.count)
            let dfaAlphaModel = DFAStreamModel(artifactCorrectionThreshold: artifactCorrectionThreshold)
            var lastProgress = 0.0
            
            var dfaValues = [Double].init(repeating: 0, count: strongValues.count)
            
            for (index, frame) in strongValues.enumerated() {
                var dfaAlpha1: Double?
                if let rrIntervals = frame.rrIntervals {
                    for rrValue in rrIntervals {
                        dfaAlphaModel.add(value: rrValue)
                    }
                    dfaAlpha1 = try? dfaAlphaModel.compute().beta
                }
                
                dfaValues[index] = dfaAlpha1 ?? 0
                
                let newProgress = Double(index + 1) / numberOfValues
                if newProgress - lastProgress > 0.01 {
                    lastProgress = newProgress
                    DispatchQueue.main.async {
                        self?.dfaAlphaComputation = .loading(progress: newProgress)
                    }
                }
            }
            DispatchQueue.main.async {
                self?.model.workoutStore.update(dfa: dfaValues, for: workoutID)
                self?.dfaAlphaValues = dfaValues
                self?.dfaAlphaComputation = .loaded(())
                self?.computeDFAPowerReg(config: .default)
            }
        }
    }
    
    func computeMeanMaximumPower() {
        guard case LoadingState.idle = meanMaximumPower else { return }
        if workout.powerCurve != nil { return }
        
        self.meanMaximumPower = .loading(progress: 0)
        let powerData = self.powerData
        let workoutID = workout.id
        DispatchQueue.global().async { [weak self] in
            let curve = MeanMaximalPower().generate(powers: powerData) { progress in
                DispatchQueue.main.async {
                    self?.meanMaximumPower = .loading(progress: progress)
                }
            }
            DispatchQueue.main.async {
                self?.model.workoutStore.update(curve, for: workoutID)
                self?.meanMaximumPower = .loaded(curve)
            }
        }
    }
    
    func computeDFAPowerReg(config: DFAAlphaRegression.Config) {
        
        guard workout.hasDFAValues else { return }
        
        var shouldCompute = true
        if
            case LoadingState.loaded(let result) = dfaRegression,
            result.config == config
        {
            shouldCompute = false
        }
        
        guard shouldCompute else { return }
        
        let strongValues = workout.values
        self.dfaRegression = .loading()
        
        DispatchQueue.global().async { [weak self] in
            do {
                let linearRegression = try DataFrameLinearRegression(
                    yValues: strongValues.map { Double($0.power ?? 0) },
                    xValues: strongValues.map { Double($0.dfaAlpha1 ?? 0) },
                    averagingInterval: config.averageInterval,
                    xAxisOffset: config.dfaAlphaOffset,
                    isIncluded: { (dfaAlpha, _) in (config.dfaLowerBound...config.dfaUpperBound).contains(dfaAlpha) }
                )
                let regression = try linearRegression.compute()
                DispatchQueue.main.async {
                    self?.dfaRegression = .loaded(
                        DFAAlphaRegression(
                            regresion: regression,
                            estimate: .init(regresion: regression.regression),
                            config: config
                        )
                    )
                }
            } catch {
                print("Data Frame Reg error: \(error)")
                DispatchQueue.main.async {
                    self?.dfaRegression = .failed(error)
                }
            }
        }
    }
    
    func detectLSCT() {
        guard case LoadingState.idle = lsctDetection else { return }
        let dataFrames = workout.values
        lsctDetection = .loading(progress: nil)
        let ftp = Double(model.settings.ftp ?? 280)
        DispatchQueue.global().async { [weak self] in
            
            let detector = LSCTDetector(
                dataFrames: dataFrames,
                stages: .defaultWith(ftp: ftp)
            )
            
            do {
                let detection = try detector.detectTest()
                self?.lsctDetectorProgressPublisher = nil
                DispatchQueue.main.async {
                    self?.lsctDetection = .loaded(detection)
                }
            } catch {
                print("LSCT Detector Error: \(error)")
                self?.lsctDetectorProgressPublisher?.cancel()
                self?.lsctDetectorProgressPublisher = nil
                DispatchQueue.main.async {
                    self?.lsctDetection = .failed(error)
                }
            }
        }
    }
}
