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
                        if let power = power(proxy.size) {
                            LineChartView(data: power)
                                .card()
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
                        if let heartRate = heartRate(proxy.size) {
                            LineChartView(data: heartRate)
                                .card()
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
                        if let cadence = cadence(proxy.size) {
                            
                            LineChartView(data: cadence)
                                .card()
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
                        if let dfaAlpha = alpha(proxy.size) {
                            LineChartView(data: dfaAlpha)
                                .card()
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
    
    func power(_ size: CGSize) -> LineChartData? {
        guard result.power != nil else { return nil }
        let baselineValues = baselineFrames.map { Double($0.power?.value ?? 0) }
        let values = workoutFrames.map { Double($0.power?.value ?? 0) }
        return LineChartData(dataSets: [
            LineChartDataSet.dataSet(values: baselineValues, maxDataPoints: Int(size.width) / scale, label: "Baseline", color: baselineColor),
            LineChartDataSet.dataSet(values: values, maxDataPoints: Int(size.width) / scale, label: "Workout", color: workoutColor),
        ])
    }
    
    func cadence(_ size: CGSize) -> LineChartData? {
        guard result.cadence != nil else { return nil }
        let baselineValues = baselineFrames.map { Double($0.cadence?.value ?? 0) }
        let values = workoutFrames.map { Double($0.cadence?.value ?? 0) }
        return LineChartData(dataSets: [
            LineChartDataSet.dataSet(values: baselineValues, maxDataPoints: Int(size.width) / scale, label: "Baseline", color: baselineColor),
            LineChartDataSet.dataSet(values: values, maxDataPoints: Int(size.width) / scale, label: "Workout", color: workoutColor),
        ])
    }
    
    func alpha(_ size: CGSize) -> LineChartData? {
        guard result.dfaAlpha1 != nil else { return nil }
        let baselineValues = baselineFrames.map { $0.heartRate?.dfaAlpha1 ?? 0 }
        let values = workoutFrames.map { $0.heartRate?.dfaAlpha1 ?? 0 }
        return LineChartData(dataSets: [
            LineChartDataSet.dataSet(values: baselineValues, maxDataPoints: Int(size.width) / scale, label: "Baseline", color: baselineColor),
            LineChartDataSet.dataSet(values: values, maxDataPoints: Int(size.width) / scale, label: "Workout", color: workoutColor),
        ])
    }
    
    func heartRate(_ size: CGSize) -> LineChartData? {
        guard result.heartRate != nil else { return nil }
        let baselineValues = baselineFrames.map { Double($0.heartRate?.value ?? 0) }
        let values = workoutFrames.map { Double($0.heartRate?.value ?? 0) }
        return LineChartData(dataSets: [
            LineChartDataSet.dataSet(values: baselineValues, maxDataPoints: Int(size.width) / scale, label: "Baseline", color: baselineColor),
            LineChartDataSet.dataSet(values: values, maxDataPoints: Int(size.width) / scale, label: "Workout", color: workoutColor),
        ])
    }
}

//struct LSCTResultDetailView_Previews: PreviewProvider {
//    static var previews: some View {
//        LSCTResultDetailView()
//    }
//}
