//
//  LSCTResultDetailView.swift
//  Fatigue
//
//  Created by Mats Mollestad on 23/10/2021.
//

import SwiftUI
import Charts

extension Double {
    func formatted(with formatter: NumberFormatter) -> String {
        return formatter.string(from: .init(value: self)) ?? "\(self)"
    }
}

struct LSCTResultDetailView: View {
    
    let baseline: Workout
    let workout: Workout
    
    let result: LSCTResult
    
    let baselineColor: Color = .red
    let workoutColor: Color = .blue
    
    var chartAspectRatio: CGFloat = 2
    
    func numberString(_ number: Double) -> String {
        return NumberFormatter.defaultFormatter.string(from: .init(value: number)) ?? "\(number)"
    }
    
    let xAxisFormatter = TimeAxisValueFormatter()
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                LSCTResultView(lsctResult: .init(lsctResult: result)).card()
                
                if let powerResult = result.power {
                    WorkoutValueView(
                        type: .power,
                        value: numberString(powerResult.absoluteDifferance)
                    )
                    GeometryReader { proxy in
                        if let power = data(for: \.power?.value.asDouble, size: proxy.size) {
                            LineChartView(data: power)
                                .xAxis(formatter: xAxisFormatter)
                        }
                    }
                    .aspectRatio(chartAspectRatio, contentMode: .fit)
                    .frame(maxWidth: .infinity)
                }
                
                if let hrResult = result.heartRate {
                    WorkoutValueView(
                        type: .heartRate,
                        value: hrResult.lastStageDiff.absoluteDifferance.formatted(with: .defaultFormatter)
                    )
                    WorkoutValueView(
                        type: .hrr,
                        value: numberString(hrResult.hrrAnalysis.absoluteDifferance)
                    )
                    WorkoutValueView(
                        type: .intensityResponse,
                        value: numberString(hrResult.intensityResponse.beta)
                    )
                    GeometryReader { proxy in
                        if let heartRate = data(for: \.heartRate?.value.asDouble, size: proxy.size) {
                            LineChartView(data: heartRate)
                                .xAxis(formatter: xAxisFormatter)
                        }
                    }
                    .aspectRatio(chartAspectRatio, contentMode: .fit)
                    .frame(maxWidth: .infinity)
                }
                
                if let cadenceResult = result.cadence {
                    WorkoutValueView(
                        type: .cadence,
                        value: numberString(cadenceResult.absoluteDifferance)
                    )
                    GeometryReader { proxy in
                        if let cadence = data(for: \.cadence?.value.asDouble, size: proxy.size) {
                            
                            LineChartView(data: cadence)
                                .xAxis(formatter: xAxisFormatter)
                        }
                    }
                    .aspectRatio(chartAspectRatio, contentMode: .fit)
                    .frame(maxWidth: .infinity)
                }
                 
                if let alphaResult = result.dfaAlpha1 {
                    WorkoutValueView(
                        type: .dfaAlpha1,
                        value: numberString(alphaResult.absoluteDifferance)
                    )
                    GeometryReader { proxy in
                        if let dfaAlpha = data(for: \.heartRate?.dfaAlpha1, size: proxy.size) {
                            LineChartView(data: dfaAlpha)
                                .xAxis(formatter: xAxisFormatter)
                        }
                    }
                    .aspectRatio(chartAspectRatio, contentMode: .fit)
                    .frame(maxWidth: .infinity)
                }
            }
            .padding()
        }
        .navigationTitle("LSCT Result")
    }
    
    var scale: Int { 3 }
    
    var baselineFrames: Array<WorkoutFrame>.SubSequence {
        let baselineStart = result.baselineRunIdentifier.startingAt
        let baselineIndex = baselineStart...(baselineStart + result.duration)
        return baseline.frames[baselineIndex]
    }
    
    var workoutFrames: Array<WorkoutFrame>.SubSequence {
        let start = result.runIdentifer.startingAt
        let indexRange = start...(start + result.duration)
        return workout.frames[indexRange]
    }
    
    func data(for valuePath: KeyPath<WorkoutFrame, Double?>, size: CGSize) -> LineChartData? {
        guard result.power != nil else { return nil }
        
        let baselineValues = baselineFrames.map { $0[keyPath: valuePath] ?? 0 }
        let values = workoutFrames.map { $0[keyPath: valuePath] ?? 0 }
        let xScale = Double(values.count * scale) / Double(size.width)
        return LineChartData(dataSets: [
            LineChartDataSet.dataSet(values: baselineValues, maxDataPoints: Int(size.width) / scale, label: "Baseline", color: baselineColor, xScale: xScale),
            LineChartDataSet.dataSet(values: values, maxDataPoints: Int(size.width) / scale, label: "Workout", color: workoutColor, xScale: xScale),
        ])
    }
}

//struct LSCTResultDetailView_Previews: PreviewProvider {
//    static var previews: some View {
//        LSCTResultDetailView()
//    }
//}
