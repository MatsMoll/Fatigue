//
//  DFAAlpha1RegressionView.swift
//  Fatigue
//
//  Created by Mats Mollestad on 04/06/2021.
//

import SwiftUI

struct DFAAlpha1RegressionView: View {
    
    internal init(maxDataPoints: Int, aspectRatio: CGFloat, dfaAlphaRegression: WorkoutSessionViewModel.State<DFAAlphaComputation>, config: Binding<DFAAlphaRegressionConfig>) {
        self.maxDataPoints = maxDataPoints
        self.aspectRatio = aspectRatio
        self.dfaAlphaRegression = dfaAlphaRegression
        self._config = config
    }
    
    
    let maxDataPoints: Int
    
    let aspectRatio: CGFloat
    
    let dfaAlphaRegression: WorkoutSessionViewModel.State<DFAAlphaComputation>
    
    @Binding
    var config: DFAAlphaRegressionConfig
    
    @State
    var editConfig: Bool = false
    
    var body: some View {
        switch dfaAlphaRegression {
        case .unavailable: Text("Derived DFA Alpha 1 - Unavailable")
        case .computing:
            VStack {
                Text("Derived DFA Alpha 1")
                ProgressView("Computing")
                    .progressViewStyle(CircularProgressViewStyle())
            }
            .padding()

        case .computed(let computation):
            VStack {
                Button(action: {
                    editConfig = true
                }, label: {
                    Label("Edit DFA Regression Settings", systemImage: "gearshape.fill")
                })
                .sheet(isPresented: $editConfig) {
                    #if os(iOS)
                    NavigationView {
                        DFAAlpha1RegressionSettingsView(
                            config: $config,
                            showSettings: $editConfig
                        )
                    }
                    #elseif os(OSX)
                    DFAAlpha1RegressionSettingsView(
                        config: $config,
                        showSettings: $editConfig
                    )
                    #endif
                }
                
                HStack {
                    VStack {
                        VStack {
                            Text("Anaerobic Threshold")
                                .font(.title3)
                                .foregroundColor(.primary)

                            Text("\(computation.estimate.anarobicThreshold) Watts")
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        
                        VStack {
                            Text("Aerobic Threshold")
                                .font(.title3)
                                .foregroundColor(.primary)

                            Text("\(computation.estimate.arobicThreshold) Watts")
                                .foregroundColor(.secondary)
                        }
                        .padding()
                    }
                    .padding()

                    Spacer()

                    
                    VStack {
                        VStack {
                            Text("Regression Result")
                                .font(.title3)
                                .foregroundColor(.primary)

                            Text("\(computation.regresion.regression.alpha) \(computation.regresion.regression.beta.sign == .plus ? "+" : "-") \(abs(computation.regresion.regression.beta)) * dfa = power")
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        
                        VStack {
                            Text("Mean Square Error")
                                .font(.title3)
                                .foregroundColor(.primary)

                            Text("\(computation.regresion.meanSquareError) or sqrt => \(sqrt(computation.regresion.meanSquareError))")
                                .foregroundColor(.secondary)
                        }
                        .padding()
                    }
                    .padding()
                }
                .padding()
            }

            CombinedChartView(
                data: computation.chartData(maxDataPoints: maxDataPoints)
            )
            .aspectRatio(aspectRatio, contentMode: .fit)
            .frame(maxWidth: .infinity)
        }
    }
}

struct DFAAlpha1RegressionView_Previews: PreviewProvider {
    static var previews: some View {
        DFAAlpha1RegressionView(
            maxDataPoints: .max,
            aspectRatio: 1.5,
            dfaAlphaRegression: .unavailable,
            config: .constant(.default)
        )
    }
}
