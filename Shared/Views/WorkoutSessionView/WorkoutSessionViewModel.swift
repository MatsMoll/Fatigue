//
//  WorkoutSessionViewModel.swift
//  Fatigue
//
//  Created by Mats Mollestad on 04/06/2021.
//

import Foundation
import Combine
import Charts

class WorkoutSessionViewModel: Identifiable, ObservableObject {
    
    enum State<T> {
        case unavailable
        case computing(progress: Double)
        case computed(T)
    }
    
    var id: UUID { workout.id }
    
    @Published
    var workout: Workout
    
    @Published
    var dfaRegressionConfig: DFAAlphaRegressionConfig
    
    @Published
    var alphaComputation: State<DFAAlphaComputation> = .unavailable
    
    @Published
    var meanMaximumPower: State<MeanMaximalPower.Curve> = .unavailable
    
    @Published
    var hasDfaAlpha1Values: State<Bool> = .unavailable
    
    @Published
    var lsctDetection: State<LSCTDetector.Detection> = .unavailable
    
    private var lsctDetectorProgressPublisher: AnyCancellable?
    
    private var dfaRegressionConfigDidUpdate: AnyCancellable?
    
    init(workout: Workout) {
        self.workout = workout
        self.dfaRegressionConfig = .default
        dfaRegressionConfigDidUpdate = $dfaRegressionConfig
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] config in
                self?.computeDFAPowerReg(config: config)
        })
    }
    
    var dfaAlphaValues: [Double] {
        workout.values.map { $0.dfaAlpha1 ?? 0 }
    }
    
    var heartRateData: [Double] {
        workout.values.map { Double($0.heartRate ?? 0) }
    }
    
    var powerData: [Double] {
        workout.values.map { Double($0.power ?? 0) }
    }
    
    var cadenceData: [Double] {
        workout.values.map { Double($0.cadence ?? 0) }
    }
    
    func workoutChartData(maxDataPoints: Int) -> LineChartData {
        LineChartData(
            dataSets: [
                LineChartDataSet.dataSet(values: heartRateData, maxDataPoints: maxDataPoints, label: "Heart Rate", color: .red),
                LineChartDataSet.dataSet(values: cadenceData, maxDataPoints: maxDataPoints, label: "Cadence", color: .blue),
                LineChartDataSet.dataSet(values: powerData, maxDataPoints: maxDataPoints, label: "Power", color: .orange)
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
    
    func computeDfaAlpha1(artifactCorrectionThreshold: Double = 0.05) {
        guard case State.unavailable = hasDfaAlpha1Values else { return }
        hasDfaAlpha1Values = .computing(progress: 0)
        var strongValues = workout.values
        DispatchQueue.global().async { [weak self] in
            let numberOfValues = Double(strongValues.count)
            let dfaAlphaModel = DFAStreamModel(artifactCorrectionThreshold: artifactCorrectionThreshold)
            var lastProgress = 0.0
            for (index, frame) in strongValues.enumerated() {
                var dfaAlpha1: Double?
                if let rrIntervals = frame.rrIntervals {
                    for rrValue in rrIntervals {
                        dfaAlphaModel.add(value: rrValue)
                    }
                    dfaAlpha1 = try? dfaAlphaModel.compute().beta
                }
                
                strongValues[index] = Workout.DataFrame(
                    timestamp: frame.timestamp,
                    heartRate: frame.heartRate,
                    power: frame.power,
                    cadence: frame.cadence,
                    dfaAlpha1: dfaAlpha1,
                    rrIntervals: frame.rrIntervals,
                    ratingOfPervicedEffort: frame.ratingOfPervicedEffort
                )
                
                let newProgress = Double(index + 1) / numberOfValues
                if newProgress - lastProgress > 0.01 {
                    lastProgress = newProgress
                    DispatchQueue.main.async {
                        self?.hasDfaAlpha1Values = .computing(progress: newProgress)
                    }
                }
            }
            DispatchQueue.main.async {
                self?.workout.values = strongValues
                self?.hasDfaAlpha1Values = .computed(true)
                self?.computeDFAPowerReg(config: .default)
            }
        }
    }
    
    func computeMeanMaximumPower() {
        guard case State.unavailable = meanMaximumPower else { return }
        let powerData = workout.values.map { Double($0.power ?? 0) }
        self.meanMaximumPower = .computing(progress: 0)
        DispatchQueue.global().async { [weak self] in
            let curve = MeanMaximalPower().generate(powers: powerData) { progress in
                DispatchQueue.main.async {
                    self?.meanMaximumPower = .computing(progress: progress)
                }
            }
            DispatchQueue.main.async {
                self?.meanMaximumPower = .computed(curve)
            }
        }
    }
    
    func computeDFAPowerReg(config: DFAAlphaRegressionConfig) {
        guard
            case State.computed(_) = hasDfaAlpha1Values
        else { return }
        
        var shouldCompute = true
        if
            case State.computed(let result) = alphaComputation,
            result.config == config
        {
            shouldCompute = false
        }
        
        guard shouldCompute else { return }
        
        let strongValues = workout.values
        self.alphaComputation = .computing(progress: 0.5)
        
        DispatchQueue.global().async { [weak self] in
            do {
                let linearRegression = try DataFrameLinearRegression(
                    yValues: strongValues.map { Double($0.power ?? 0) },
                    xValues: strongValues.map { Double($0.dfaAlpha1 ?? 0) },
                    averagingInterval: config.averageInterval,
                    xAxisOffset: config.dfaAlphaOffset,
                    isIncluded: { (dfaAlpha, _) in (config.dfaLowerBound...config.dfaUpperBound).contains(dfaAlpha) }
                )
                let regression = linearRegression.compute()
                DispatchQueue.main.async {
                    self?.alphaComputation = .computed(
                        DFAAlphaComputation(
                            regresion: regression,
                            estimate: .init(regresion: regression.regression),
                            config: config
                        )
                    )
                }
            } catch {
                print("Data Frame Reg error: \(error)")
                DispatchQueue.main.async {
                    self?.alphaComputation = .unavailable
                }
            }
        }
    }
    
    func detectLampartSumMaximalTest(ftp: Double) {
        guard case State.unavailable = lsctDetection else { return }
        let dataFrames = workout.values
        lsctDetection = .computing(progress: 0)
        DispatchQueue.global().async { [weak self] in
            
            let detector = LSCTDetector(
                dataFrames: dataFrames,
                stages: .defaultWith(ftp: ftp)
            )
            
            self?.lsctDetectorProgressPublisher = detector.progressPublisher
                .receive(on: DispatchQueue.main)
                .sink(receiveValue: { self?.lsctDetection = .computing(progress: $0) })
            
            do {
                let detection = try detector.detectTest()
                self?.lsctDetectorProgressPublisher = nil
                DispatchQueue.main.async {
                    self?.lsctDetection = .computed(detection)
                }
            } catch {
                print("LSCT Detector Error: \(error)")
                self?.lsctDetectorProgressPublisher?.cancel()
                self?.lsctDetectorProgressPublisher = nil
                DispatchQueue.main.async {
                    self?.lsctDetection = .unavailable
                }
            }
        }
    }
}
