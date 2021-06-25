//
//  DFAAlpha1RegressionView.swift
//  Fatigue
//
//  Created by Mats Mollestad on 04/06/2021.
//

import SwiftUI

struct DFAAlpha1RegressionView: View {
    
    let maxDataPoints: Int
    let aspectRatio: CGFloat
    
    @State var editConfig: Bool = false
    
    @EnvironmentObject var viewModel: WorkoutSessionViewModel
    
    #if os(iOS)
    @Environment(\.horizontalSizeClass)
    var sizeClass
    #endif
    
    static let numberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 0
        return formatter
    }()
    
    var body: some View {
        AsyncContentView(
            value: viewModel.dfaRegression,
            onLoad: {}
        ) { regression in
            VStack(alignment: .leading, spacing: 12) {
                Menu("Settings") {
                    Button(action: {
                        editConfig = true
                    }, label: {
                        Label("DFA Regression", symbol: .gearshapeFill)
                    })
                }
                .sheet(isPresented: $editConfig) {
                    #if os(iOS)
                    NavigationView {
                        DFAAlpha1RegressionSettingsView(
                            config: $viewModel.config,
                            showSettings: $editConfig
                        )
                    }
                    #elseif os(OSX)
                    DFAAlpha1RegressionSettingsView(
                        config: $viewModel.config,
                        showSettings: $editConfig
                    )
                    #endif
                }

                #if os(iOS)
                if sizeClass == .compact {
                    estimates(computation: regression)

                    regressionDetails(regresion: regression.regresion)
                } else {
                    HStack {
                        VStack(alignment: .leading) {
                            estimates(computation: regression)
                        }
                        
                        Spacer()

                        VStack(alignment: .leading) {
                            regressionDetails(regresion: regression.regresion)
                        }
                    }
                }
                #elseif os(OSX)
                HStack {
                    VStack(alignment: .leading) {
                        estimates(computation: regression)
                    }
                    
                    Spacer()

                    VStack(alignment: .leading) {
                        regressionDetails(regresion: regression.regresion)
                    }
                }
                #endif
            }

            CombinedChartView(
                data: regression.chartData(maxDataPoints: maxDataPoints)
            )
            .aspectRatio(aspectRatio, contentMode: .fit)
            .frame(maxWidth: .infinity)
        }
        .onAppear {
            viewModel.computeDFAPowerReg(config: viewModel.config)
        }
    }
    
    @ViewBuilder
    func estimates(computation: DFAAlphaRegression) -> some View {
        ValueView(
            title: "Anaerobic Threshold",
            value: "\(computation.estimate.anarobicThreshold) watts"
        )
        
        ValueView(
            title: "Aerobic Threshold",
            value: "\(computation.estimate.arobicThreshold) watts"
        )
    }
    
    @ViewBuilder
    func regressionDetails(regresion: DataFrameLinearRegression.Result) -> some View {
        ValueView(
            title: "Regression Result",
            value: regresion.regression.desciption(with: Self.numberFormatter)
        )
        
        ValueView(
            title: "Mean Square Error",
            value: Self.numberFormatter.string(from: .init(value: regresion.meanSquareError)) ?? "0"
        )
    }
}

struct DFAAlpha1RegressionView_Previews: PreviewProvider {
    static var previews: some View {
        DFAAlpha1RegressionView(
            maxDataPoints: .max,
            aspectRatio: 1.5
        )
    }
}
