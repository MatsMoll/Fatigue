//
//  ComputePowerDfaRegressionView.swift
//  Fatigue
//
//  Created by Mats Mollestad on 06/12/2021.
//

import SwiftUI

struct ComputeDfaRegressionView: View {
    
    let workout: Workout
    
    @Binding
    var regression: DFAAlphaRegression?
    
    let too: KeyPath<WorkoutFrame, Int?>
    
    let valueType: WorkoutValueType
    
    @State
    var config: DFAAlphaRegression.Config = .default
    
    @State
    var error: Error? = nil
    
    private let aspectRatio = 1.4
    
    var body: some View {
        if let regression = regression {
            CombinedChartView(
                data: regression.chartData(
                    title: "DFA Alpha 1 - \(valueType.name)",
                    maxDataPoints: 300,
                    startX: config.dfaLowerBound - 0.1,
                    endX: config.dfaUpperBound + 0.1,
                    lineColor: valueType.tintColor
                )
            )
            .aspectRatio(aspectRatio, contentMode: .fit)
            .frame(maxWidth: .infinity)
            
            WorkoutValueView(
                type: .anarobicThreshold.withUnits(from: valueType),
                value: regression.estimate.anarobicThreshold.formatted()
            )
            
            WorkoutValueView(
                type: .arobicThreshold.withUnits(from: valueType),
                value: regression.estimate.arobicThreshold.formatted()
            )
        } else if let error = error {
            Text("Error: \(error.localizedDescription)")
                .foregroundColor(.secondary)
                .padding()
        } else {
            ProgressView("Computing Regression")
                .task { await computeRegression() }
        }
    }
    
    func computeRegression() async {
        do {
            let linearRegression = try DataFrameLinearRegression(
                yValues: workout.frames.map { Double($0[keyPath: too] ?? 0) },
                xValues: workout.frames.map { Double($0.heartRate?.dfaAlpha1 ?? 0) },
                averagingInterval: config.averageInterval,
                xAxisOffset: config.dfaAlphaOffset,
                isIncluded: { (dfaAlpha, tooValue) in config.dfaRange.contains(dfaAlpha) && tooValue > 0 }
            )
            let regression = try await linearRegression.compute()
            guard !regression.values.isEmpty else {
                throw GenericError(reason: "To few values for regression")
            }
            DispatchQueue.main.async {
                self.regression = .init(
                    regresion: regression,
                    estimate: .init(regresion: regression.regression),
                    config: config
                )
            }
        } catch {
            DispatchQueue.main.async {
                self.error = error
            }
        }
    }
}

struct ComputePowerDfaRegressionView_Previews: PreviewProvider {
    static var previews: some View {
        ComputeDfaRegressionView(
            workout: .init(id: .init(), startedAt: .init(), values: [], laps: []),
            regression: .constant(nil),
            too: \.power?.value,
            valueType: .power
        )
    }
}
