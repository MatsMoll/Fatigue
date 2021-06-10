//
//  WorkoutSessionView.swift
//  Fatigue
//
//  Created by Mats Mollestad on 30/05/2021.
//

import SwiftUI
import Charts
import Combine

struct DFAAlphaRegressionConfig: Equatable {
    
    var averageInterval: Int
    var dfaAlphaOffset: Int
    var dfaUpperBound: Double
    var dfaLowerBound: Double
    
    static let `default` = DFAAlphaRegressionConfig(
        averageInterval: 5,
        dfaAlphaOffset: 2 * 60,
        dfaUpperBound: 0.8,
        dfaLowerBound: 0.4
    )
}

struct DFAAlphaComputation {
    let regresion: DataFrameLinearRegression.Result
    let estimate: DFAAlphaEstimate
    let config: DFAAlphaRegressionConfig
}

struct DFAAlphaEstimate {
    let anarobicThreshold: Int
    let arobicThreshold: Int
    
    init(regresion: LinearRegression.Result) {
        anarobicThreshold = Int((regresion.alpha + regresion.beta * 0.5).rounded())
        arobicThreshold = Int((regresion.alpha + regresion.beta * 0.75).rounded())
    }
}

struct WorkoutSessionView: View {
    
    @ObservedObject
    var viewModel: WorkoutSessionViewModel
    
    @ObservedObject
    var userSetting: UserSettings
    
    let sizeModifier: CGFloat = 2
    let chartAspectRatio: CGFloat = 2
    
    let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .medium
        return formatter
    }()
    
    var body: some View {
        GeometryReader { proxy in
            List {
                Section(header: Text("Workout")) {
                    LineChartView(
                        data: viewModel.workoutChartData(maxDataPoints: Int(proxy.size.width / sizeModifier))
                    )
                    .xAxis(formatter: TimeAxisValueFormatter(scale: scale(width: proxy.size.width)))
                    .aspectRatio(chartAspectRatio, contentMode: .fit)
                    .frame(maxWidth: .infinity)
//                    .whenHovered({ test in
//                        print("Test: \(test)")
//                    })
                }

                Section(header: Text("DFA Alpha 1")) {
                    switch viewModel.hasDfaAlpha1Values {
                    case .unavailable: Text("")
                    case .computing(let progress):
                        VStack {
                            Text("DFA Alpha 1")
                                .font(.title)
                            ProgressView("Computed \(Int(progress * 100))%", value: progress)
                        }
                        .padding()
                    case .computed(_):
                        LineChartView(
                            data: viewModel.dfaAlpha(maxDataPoints: Int(proxy.size.width / sizeModifier))
                        )
                            .xAxis(formatter: TimeAxisValueFormatter(scale: scale(width: proxy.size.width)))
                        .aspectRatio(chartAspectRatio, contentMode: .fit)
                        .frame(maxWidth: .infinity)
                    }
                }
                
                Section(header: Text("LSCT Detection")) {
                    LSCTDetectionView(lsctDetection: $viewModel.lsctDetection)
                }

                Section(header: Text("DFA Regression")) {
                    DFAAlpha1RegressionView(
                        maxDataPoints: Int(proxy.size.width / sizeModifier),
                        aspectRatio: chartAspectRatio,
                        dfaAlphaRegression: viewModel.alphaComputation,
                        config: $viewModel.dfaRegressionConfig
                    )
                }
                
                Section(header: Text("Mean Maximum Power Curve")) {
                    MeanMaximumPowerView(
                        aspectRatio: chartAspectRatio,
                        meanMaximumPower: $viewModel.meanMaximumPower
                    )
                }
            }
            .padding()
        }
        .frame(maxWidth: 800, alignment: .center)
        .onAppear(perform: {
            viewModel.computeDfaAlpha1(artifactCorrectionThreshold: 0.05)
            viewModel.computeMeanMaximumPower()
            if let ftp = userSetting.ftp {
                viewModel.detectLampartSumMaximalTest(ftp: Double(ftp))
            }
        })
        .navigationTitle(dateFormatter.string(from: viewModel.workout.startedAt))
    }
    
    func scale(width: CGFloat) -> Double {
        guard width.isZero == false else { return 1 }
        return Double(viewModel.workout.values.count) / Double(width / sizeModifier)
    }
}

struct WorkoutSessionView_Previews: PreviewProvider {
    static var previews: some View {
        WorkoutSessionView(
            viewModel: .init(
                workout: .init(
                    id: .init(),
                    startedAt: .init(),
                    values: [
                        .init(
                            timestamp: 0,
                            heartRate: 120,
                            power: 200,
                            cadence: 90,
                            dfaAlpha1: 1.1,
                            rrIntervals: [400, 402],
                            ratingOfPervicedEffort: nil
                        ),
                        .init(
                            timestamp: 1,
                            heartRate: 123,
                            power: 210,
                            cadence: 90,
                            dfaAlpha1: 1.0,
                            rrIntervals: [400, 402],
                            ratingOfPervicedEffort: nil
                        ),
                        .init(
                            timestamp: 2,
                            heartRate: 124,
                            power: 220,
                            cadence: 90,
                            dfaAlpha1: 0.9,
                            rrIntervals: [400, 402],
                            ratingOfPervicedEffort: nil
                        )
                    ]
                )
            ),
            userSetting: .init()
        )
    }
}
