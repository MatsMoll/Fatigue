//
//  MeanMaximumPowerView.swift
//  Fatigue
//
//  Created by Mats Mollestad on 04/06/2021.
//

import SwiftUI

struct MeanMaximumPowerView: View {
    
    let aspectRatio: CGFloat
    
    @Binding
    var meanMaximumPower: WorkoutSessionViewModel.State<MeanMaximalPower.Curve>
    
    let minimumSpacing = 0.05
    
    var body: some View {
        switch meanMaximumPower {
        case .unavailable: Text("")
        case .computing(let progress):
            VStack {
                Text("Mean Maximum Power Curve")
                    .font(.title)
                ProgressView("Computed \(Int(progress * 100))%", value: progress)
            }
            .padding()
        case .computed(let curve):
            LineChartView(data: curve.lineChartData(minimumSpacing: minimumSpacing))
                .xAxis(formatter: curve.axisFormatter(minimumSpacing: minimumSpacing))
                .aspectRatio(aspectRatio, contentMode: .fit)
                .frame(maxWidth: .infinity)
        }
    }
}

struct MeanMaximumPowerView_Previews: PreviewProvider {
    static var previews: some View {
        MeanMaximumPowerView(aspectRatio: 1.5, meanMaximumPower: .constant(.computing(progress: 0.5)))
    }
}
