//
//  WorkoutLineChart.swift
//  Fatigue
//
//  Created by Mats Mollestad on 16/10/2021.
//

import SwiftUI
import Charts

struct WorkoutLineChart: View {
    
    let workout: Workout
    
    let type: WorkoutValueType
    
    let frameKey: KeyPath<WorkoutFrame, Double?>
    
    var chartAspectRatio: CGFloat = 1.5
    
    var body: some View {
        VStack(alignment: .leading) {
            Label(
                title: { Text(type.name.uppercased()).foregroundColor(Color.init(UIColor.secondaryLabel)) },
                icon: { Image(symbol: type.symbol).foregroundColor(type.tintColor) }
            )
            .font(.footnote)
            
            GeometryReader { proxy in
                LineChartView(
                    data: lineChartData(maxPoints: Int(proxy.size.width / 3))
                )
            }
            .aspectRatio(chartAspectRatio, contentMode: .fit)
            .frame(maxWidth: .infinity)
            .card()
        }
    }
    
    private func lineChartData(maxPoints: Int) -> LineChartData {
        var values = [Double]()
        
        for frame in workout.frames {
            values.append(frame[keyPath: frameKey] ?? 0)
        }
        
        return LineChartData(dataSets: [
            LineChartDataSet.dataSet(type: type, values: values, maxDataPoints: maxPoints)
        ])
    }
}

struct WorkoutLineChart_Previews: PreviewProvider {
    static var previews: some View {
        WorkoutLineChart(workout: .init(id: .init(), startedAt: .init(), values: [], laps: []), type: .power, frameKey: \.power?.value.asDouble)
    }
}
