//
//  WorkoutSessionView.swift
//  Fatigue
//
//  Created by Mats Mollestad on 30/05/2021.
//

import SwiftUI
import Charts
import Combine

struct DFAAlphaRegression {
    struct Config: Equatable {
        
        var averageInterval: Int
        var dfaAlphaOffset: Int
        var dfaUpperBound: Double
        var dfaLowerBound: Double
        
        static let `default` = Config(
            averageInterval: 5,
            dfaAlphaOffset: 2 * 60,
            dfaUpperBound: 0.8,
            dfaLowerBound: 0.4
        )
    }
    
    let regresion: DataFrameLinearRegression.Result
    let estimate: DFAAlphaEstimate
    let config: Config
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
    
    @StateObject
    var viewModel: WorkoutSessionViewModel
    
    let sizeModifier: CGFloat = 2
    let chartAspectRatio: CGFloat = 1.5
    
    static let numberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 2
        return formatter
    }()
    
    @State
    var shouldExport: Bool = false
    
    @State
    var csvFile: CSVFile?
    
    var body: some View {
        GeometryReader { proxy in
            List {
                Section(header: Label("Summary", symbol: .sum)) {

                    ValueView(
                        title: "Elapsed Time",
                        value: viewModel.duration,
                        symbol: .clock,
                        imageColor: .primary
                    )

                    if let powerSummary = viewModel.workout.powerSummary {
                        ValueView(
                            title: "Average Power",
                            value: "\(powerSummary.average) watts",
                            symbol: .boltFill,
                            imageColor: .blue
                        )
                        ValueView(
                            title: "Normalized",
                            value: "\(powerSummary.normalized) watts",
                            symbol: .boltFill,
                            imageColor: .blue
                        )
                        if let balance = powerSummary.powerBalance {
                            ValueView(
                                title: "Power Balance",
                                value: balance.description(),
                                symbol: .arrowtriangleAndLineVertical,
                                imageColor: .blue
                            )
                        }
                    }

                    if let heartRateSummary = viewModel.workout.heartRateSummary {
                        ValueView(
                            title: "Average Heart Rate",
                            value: "\(heartRateSummary.average) bpm",
                            symbol: .heartFill,
                            imageColor: .red
                        )
                        
                        if let dfaSummary = heartRateSummary.dfaAlpha {
                            ValueView(
                                title: "Average DFA",
                                value: Self.numberFormatter.string(from: .init(value: dfaSummary.average)) ?? "NaN",
                                symbol: .heartFill,
                                imageColor: .purple
                            )
                        }
                    }

                    if let cadenceSummary = viewModel.workout.cadenceSummary {
                        ValueView(
                            title: "Average Cadence",
                            value: Self.numberFormatter.string(from: .init(value: cadenceSummary.average)) ?? "NaN",
                            symbol: .goForwared,
                            imageColor: .orange
                        )
                    }
                }

                Section(header: Label("General", symbol: .figureWalk)) {
                    LineChartView(
                        data: viewModel.workoutChartData(maxDataPoints: Int(proxy.size.width / sizeModifier))
                    )
                    .xAxis(formatter: TimeAxisValueFormatter(scale: scale(width: proxy.size.width)))
                    .aspectRatio(chartAspectRatio, contentMode: .fit)
                    .frame(maxWidth: .infinity)
                }

//                Section(header: Label("DFA Alpha 1", symbol: .heartFill)) {
//                    AsyncContentView(
//                        value: viewModel.dfaAlphaComputation,
//                        onLoad: { viewModel.computeDfaAlpha1() }
//                    ) { viewModel in
//                        LineChartView(
//                            data: viewModel.dfaAlpha(maxDataPoints: Int(proxy.size.width / sizeModifier))
//                        )
//                        .xAxis(formatter: TimeAxisValueFormatter(scale: scale(width: proxy.size.width)))
//                        .aspectRatio(chartAspectRatio, contentMode: .fit)
//                        .frame(maxWidth: .infinity)
//                        .onAppear {
//                            viewModel.computeDFAPowerReg(config: viewModel.config)
//                        }
//                    }
//                }

                if viewModel.settings.baselineWorkoutID == nil {
                    Section(header: Label("LSCT Detection", symbol: .crossFill)) {
                        LSCTDetectionView()
                    }
                } else {
                    Section(header: Label("LSCT Result", symbol: .crossFill)) {
                        AsyncContentView(
                            value: viewModel.lsctRun
                        ) {
                            viewModel.computeLsctResult()
                        } content: { result in
                            LSCTResultView(lsctResult: .init(lsctResult: result))
                        }
                    }
                }

                Section(header: Label("DFA Alpha Regression", symbol: .waveformPathEcg)) {
                    DFAAlpha1RegressionView(
                        maxDataPoints: Int(proxy.size.width / sizeModifier),
                        aspectRatio: chartAspectRatio
                    )
                }

                Section(header: Label("Mean Maximum Power Curve", symbol: .boltFill)) {
                    MeanMaximumPowerView(aspectRatio: chartAspectRatio)
                }

                Section(header: Label("Export", symbol: .recordCircle)) {
                    Button("Export to CSV") {
                        guard csvFile == nil else {
                            shouldExport = true
                            return
                        }
                        csvFile = CSVFile(
                            elements: viewModel.workout.frames,
                            fields: [
                                ("timestamp", \.optionalTimestamp?.description),
                                ("heartRate", \.heartRate?.value.description),
                                ("dfaAlpha", \.heartRate?.dfaAlpha1?.description),
                                ("power", \.power?.value.description),
                                ("cadence", \.cadence?.value.description),
                            ]
                        )
                        shouldExport = true
                    }
                }
            }
            .listStyle(listStyle)
        }
        .frame(maxWidth: 800, alignment: .center)
        .navigationTitle(viewModel.startedAt)
        .environmentObject(viewModel)
        .fileExporter(isPresented: $shouldExport, document: csvFile, contentType: .plainText) { result in
            print("Exported: \(result)")
        }
    }
    
    var listStyle: some ListStyle {
        #if os(iOS)
        return InsetGroupedListStyle()
        #else
        return DefaultListStyle()
        #endif
    }
    
    func scale(width: CGFloat) -> Double {
        guard width.isZero == false else { return 1 }
        return Double(viewModel.powerData.count) / Double(width / sizeModifier)
    }
}

//struct WorkoutSessionView_Previews: PreviewProvider {
//    static var previews: some View {
//        WorkoutSessionView(
//            viewModel: .init(
//                workout: .init(
//                    id: .init(),
//                    startedAt: .init(),
//                    values: [
//                        .init(
//                            timestamp: 0,
//                            heartRate: 120,
//                            power: 200,
//                            cadence: 90,
//                            dfaAlpha1: 1.1,
//                            rrIntervals: [400, 402],
//                            ratingOfPervicedEffort: nil
//                        ),
//                        .init(
//                            timestamp: 1,
//                            heartRate: 123,
//                            power: 210,
//                            cadence: 90,
//                            dfaAlpha1: 1.0,
//                            rrIntervals: [400, 402],
//                            ratingOfPervicedEffort: nil
//                        ),
//                        .init(
//                            timestamp: 2,
//                            heartRate: 124,
//                            power: 220,
//                            cadence: 90,
//                            dfaAlpha1: 0.9,
//                            rrIntervals: [400, 402],
//                            ratingOfPervicedEffort: nil
//                        )
//                    ],
//                    powerCurve: nil
//                )
//            ),
//            userSetting: .init()
//        )
//    }
//}
