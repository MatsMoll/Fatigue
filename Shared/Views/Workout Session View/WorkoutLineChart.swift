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
    
    var frameRange: ClosedRange<Int>? = nil
    
    var verticalLines: [Int] = []
    
    var body: some View {
        VStack(alignment: .leading) {
            Label(
                title: { Text(type.name.uppercased()).foregroundColor(.secondary) },
                icon: { Image(symbol: type.symbol).foregroundColor(type.tintColor) }
            )
            .font(.footnote)
            
            GeometryReader { proxy in
                LineChartView(
                    data: lineChartData(maxPoints: Int(proxy.size.width / 3)),
                    laps: verticalLines
                )
                .xAxis(formatter: TimeAxisValueFormatter())
                .xScale(startX: frameRange?.lowerBound ?? 0, endX: frameRange?.upperBound ?? workout.frames.count)
            }
            .aspectRatio(chartAspectRatio, contentMode: .fit)
            .frame(maxWidth: .infinity)
        }
    }
    
    private func lineChartData(maxPoints: Int) -> LineChartData {
        var values = [Double]()
        for frame in workout.frames {
            values.append(frame[keyPath: frameKey] ?? 0)
        }
        
        let xScale = max(Double(values.count) / Double(maxPoints), 1)
        
        return LineChartData(dataSets: [
            LineChartDataSet.dataSet(type: type, values: values, maxDataPoints: maxPoints, xScale: xScale)
        ])
    }
}

struct WorkoutLineChart_Previews: PreviewProvider {
    static var previews: some View {
        WorkoutLineChart(workout: .init(id: .init(), startedAt: .init(), values: [], laps: []), type: .power, frameKey: \.power?.value.asDouble)
    }
}
