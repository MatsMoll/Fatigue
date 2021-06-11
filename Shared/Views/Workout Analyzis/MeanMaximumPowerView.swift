//
//  MeanMaximumPowerView.swift
//  Fatigue
//
//  Created by Mats Mollestad on 04/06/2021.
//

import SwiftUI

struct MeanMaximumPowerView: View {
    
    let aspectRatio: CGFloat
    
    let minimumSpacing = 0.05
    
    @EnvironmentObject var viewModel: WorkoutSessionViewModel
    
    var body: some View {
        AsyncContentView(
            value: viewModel.meanMaximumPower,
            onLoad: { viewModel.computeMeanMaximumPower() }
        ) { curve in
            LineChartView(data: curve.lineChartData(minimumSpacing: minimumSpacing))
                .xAxis(formatter: curve.axisFormatter(minimumSpacing: minimumSpacing))
                .aspectRatio(aspectRatio, contentMode: .fit)
                .frame(maxWidth: .infinity)
        }
    }
}

struct MeanMaximumPowerView_Previews: PreviewProvider {
    static var previews: some View {
        MeanMaximumPowerView(aspectRatio: 1.5)
    }
}
