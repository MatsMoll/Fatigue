//
//  LineChartView.swift
//  Fatigue
//
//  Created by Mats Mollestad on 30/05/2021.
//

import SwiftUI
import Charts
#if os(OSX)
import AppKit
#elseif os(iOS)
import UIKit
#endif

#if os(OSX)

extension View {
    func whenHovered(_ mouseIsInside: @escaping (Bool) -> Void) -> some View {
        modifier(MouseInsideModifier(mouseIsInside))
    }
}

struct MouseInsideModifier: ViewModifier {
    let mouseIsInside: (Bool) -> Void
    
    init(_ mouseIsInside: @escaping (Bool) -> Void) {
        self.mouseIsInside = mouseIsInside
    }
    
    func body(content: Content) -> some View {
        content.background(
            GeometryReader { proxy in
                Representable(mouseIsInside: mouseIsInside,
                              frame: proxy.frame(in: .global))
            }
        )
    }
    
    private struct Representable: NSViewRepresentable {
        let mouseIsInside: (Bool) -> Void
        let frame: NSRect
        
        func makeCoordinator() -> Coordinator {
            let coordinator = Coordinator()
            coordinator.mouseIsInside = mouseIsInside
            return coordinator
        }
        
        class Coordinator: NSResponder {
            var mouseIsInside: ((Bool) -> Void)?
            
            override func mouseEntered(with event: NSEvent) {
                mouseIsInside?(true)
            }
            
            override func mouseExited(with event: NSEvent) {
                mouseIsInside?(false)
            }
            
            override func mouseMoved(with event: NSEvent) {
                print(event.locationInWindow)
            }
        }
        
        func makeNSView(context: Context) -> NSView {
            let view = NSView(frame: frame)
            
            let options: NSTrackingArea.Options = [
                .mouseMoved,
                .inVisibleRect,
                .activeInKeyWindow
            ]
            
            let trackingArea = NSTrackingArea(rect: frame,
                                              options: options,
                                              owner: context.coordinator,
                                              userInfo: nil)
            
            view.addTrackingArea(trackingArea)
            
            return view
        }
        
        func updateNSView(_ nsView: NSView, context: Context) {}
        
        static func dismantleNSView(_ nsView: NSView, coordinator: Coordinator) {
            nsView.trackingAreas.forEach { nsView.removeTrackingArea($0) }
        }
    }
}

struct LineChartView: NSViewRepresentable {

    let data: LineChartData
    private let xAxisFormatter: AxisValueFormatter
    private let view: Charts.LineChartView
    
//    @Binding
//    var highlight: Double?
    
    init(
        data: LineChartData,
        xAxisFormatter: AxisValueFormatter = DefaultAxisValueFormatter(),
        view: Charts.LineChartView = Charts.LineChartView()
//        highlight: Binding<Double?> = .constant(nil)
    ) {
        self.data = data
        self.xAxisFormatter = xAxisFormatter
        self.view = view
//        self._highlight = highlight
    }
    
    func makeNSView(context: Context) -> some NSView {
        view.data = data
        view.leftAxis.axisMinimum = 0
        view.rightAxis.enabled = false
        view.highlightPerTapEnabled = true
        view.xAxis.valueFormatter = xAxisFormatter
        view.pinchZoomEnabled = false
        view.doubleTapToZoomEnabled = false
        view.leftAxis.drawAxisLineEnabled = false
        view.leftAxis.drawGridLinesEnabled = false
        view.xAxis.drawAxisLineEnabled = false
        view.xAxis.drawGridLinesEnabled = false
        view.xAxis.labelPosition = .bottom
        return view
    }
    
    func updateNSView(_ nsView: NSViewType, context: Context) {
//        print(nsView.convert(nsView.bounds, to: nil))
//
//        if let highlightValue = highlight {
//            view.highlightValue(x: highlightValue, dataSetIndex: 0)
//            var yValues = data.dataSets.map { $0.entriesForXValue(highlightValue).first!.y }
//        }
        view.data = data
    }
    
    func minYAxis(_ value: Double) -> Self {
        view.leftAxis.axisMinimum = value
        return self
    }
    
    func xAxis(formatter: AxisValueFormatter) -> Self {
        .init(
            data: data,
            xAxisFormatter: formatter,
            view: view
//            highlight: $highlight
        )
    }
}

struct CombinedChartView: NSViewRepresentable {
    
    let data: CombinedChartData
    
    init(data: CombinedChartData) {
        self.data = data
    }
    
    let view = Charts.CombinedChartView()
    
    func makeNSView(context: Context) -> some NSView {
        view.data = data
        view.leftAxis.axisMinimum = 0
        view.rightAxis.enabled = false
        view.highlightPerTapEnabled = true
        return view
    }
    
    func updateNSView(_ nsView: NSViewType, context: Context) {
//        view.data = data
    }
    
    func minYAxis(_ value: Double) -> Self {
        view.leftAxis.axisMinimum = value
        return self
    }
}
#elseif os(iOS)
struct LineChartView: UIViewRepresentable {

    let data: LineChartData
    private let xAxisFormatter: AxisValueFormatter
    private let view: Charts.LineChartView
    private let laps: [Int]
    private let visableRange: ClosedRange<Double>?
    
    init(data: LineChartData, laps: [Int] = [], visableRange: ClosedRange<Double>? = nil, xAxisFormatter: AxisValueFormatter = DefaultAxisValueFormatter(), view: Charts.LineChartView = Charts.LineChartView()) {
        self.data = data
        self.xAxisFormatter = xAxisFormatter
        self.laps = laps
        self.view = view
        self.visableRange = visableRange
    }
    
    func makeUIView(context: Context) -> some UIView {
        let lineColor: UIColor = .init(white: 0.15, alpha: 1)
        let textColor: UIColor = .lightText
        
        view.data = data
        view.leftAxis.axisMinimum = 0
        view.rightAxis.enabled = false
        view.xAxis.valueFormatter = xAxisFormatter
        view.leftAxis.axisLineColor = lineColor
        view.leftAxis.gridColor = lineColor
        view.leftAxis.labelTextColor = textColor
        view.xAxis.axisLineColor = lineColor
        view.xAxis.gridColor = lineColor
        view.xAxis.labelPosition = .bottom
        view.xAxis.labelTextColor = textColor
        view.legend.textColor = textColor
        view.doubleTapToZoomEnabled = false
        view.highlightPerTapEnabled = false
        view.highlightPerDragEnabled = false
        view.maxVisibleCount = 40
        for lap in laps {
            view.xAxis.addLimitLine(.init(limit: Double(lap)))
        }
        view.layoutIfNeeded()
        if let visableRange = visableRange {
            let padding = 1.4
            let width = (visableRange.upperBound - visableRange.lowerBound)
            let viewWidth = (visableRange.upperBound - visableRange.lowerBound) * padding
            let minX = max(0, visableRange.lowerBound)
            let scale = data.xMax / viewWidth
            let xValue = minX + width / 2
            view.zoom(scaleX: scale, scaleY: 1, xValue: xValue, yValue: 0, axis: .left)
        }
        return view
    }
    
    func updateUIView(_ nsView: UIViewType, context: Context) {
//        view.data = data
        view.data = data
    }
    
    func minYAxis(_ value: Double) -> Self {
        view.leftAxis.axisMinimum = value
        return self
    }
    
    func xAxis(formatter: AxisValueFormatter) -> Self {
        .init(data: data, laps: laps, visableRange: visableRange, xAxisFormatter: formatter, view: view)
    }
    
    func xScale(startX: Int, endX: Int) -> Self {
        return .init(data: data, laps: laps, visableRange: Double(startX)...Double(endX), xAxisFormatter: xAxisFormatter, view: view)
    }
}

struct CombinedChartView: UIViewRepresentable {
    
    let data: CombinedChartData
    
    init(data: CombinedChartData) {
        self.data = data
    }
    
    let view = Charts.CombinedChartView()
    
    func makeUIView(context: Context) -> some UIView {
        
        let lineColor: UIColor = .init(white: 0.15, alpha: 1)
        let textColor: UIColor = .lightText
        
        view.data = data
        view.leftAxis.axisMinimum = 0
        view.rightAxis.enabled = false
        view.xAxis.labelTextColor = textColor
        view.xAxis.axisLineColor = lineColor
        view.xAxis.gridColor = lineColor
        view.leftAxis.labelTextColor = textColor
        view.leftAxis.axisLineColor = lineColor
        view.leftAxis.gridColor = lineColor
        view.legend.textColor = textColor
        view.highlightPerTapEnabled = false
        view.highlightPerDragEnabled = false
        return view
    }
    
    func updateUIView(_ nsView: UIViewType, context: Context) {
//        view.data = data
    }
    
    func minYAxis(_ value: Double) -> Self {
        view.leftAxis.axisMinimum = value
        return self
    }
}
#endif

extension Array where Element == Double {
    func compress(maxDataPoints: Int) -> [Double] {
        if maxDataPoints == 0 {
            return self.compress(maxDataPoints: self.count)
        }
        let slidingWindow = Int(Double(self.count) / Double(maxDataPoints))
        if slidingWindow <= 1 { return self }
        let numberOfDataPoints = Int(ceil(Double(self.count) / Double(slidingWindow)))
        
        var returnData = [Double].init(repeating: 0, count: numberOfDataPoints)
        for i in 0..<numberOfDataPoints {
            
            var valueSum: Double = 0
            var numberOfValues = 0
            
            for j in 0..<slidingWindow {
                let index = i * slidingWindow + j
                if index < self.count {
                    valueSum += self[index]
                    numberOfValues += 1
                }
            }
            returnData[i] = valueSum / Double(numberOfValues)
        }
        return returnData
    }
}

extension LineChartDataSet {
    
    static func dataSet(values: [Double], maxDataPoints: Int, label: String, color: Color, xScale: Double = 1, fillOpacity: Double = 0.6, startX: Double = 0) -> LineChartDataSet {
        let dataSet = LineChartDataSet(
            entries: values.compress(maxDataPoints: maxDataPoints)
                .enumerated()
                .map { ChartDataEntry(x: Double($0.offset) * xScale + startX, y: $0.element) },
            label: label
        )
        dataSet.drawCircleHoleEnabled = false
        dataSet.drawCirclesEnabled = false
        dataSet.drawHorizontalHighlightIndicatorEnabled = false
        dataSet.lineWidth = 3
        dataSet.drawFilledEnabled = fillOpacity != 0
        #if os(OSX)
        dataSet.fillColor = NSColor(color.opacity(fillOpacity))
        dataSet.colors = [NSColor(color)]
        #elseif os(iOS)
        dataSet.fillColor = UIColor(color.opacity(fillOpacity))
        dataSet.colors = [UIColor(color)]
        #endif
        return dataSet
    }
    
    static func dataSet(type: WorkoutValueType, values: [Double], maxDataPoints: Int, xScale: Double = 1, fillOpacity: Double = 0.6, startX: Double = 0) -> LineChartDataSet {
        return .dataSet(values: values, maxDataPoints: maxDataPoints, label: type.name, color: type.tintColor, xScale: xScale, fillOpacity: fillOpacity, startX: startX)
    }
    
    static func dataSet(values: [(Double, Double)], label: String, color: Color, fillOpacity: Double = 0.6, startX: Double = 0) -> LineChartDataSet {
        let dataSet = LineChartDataSet(
            entries: values.map { ChartDataEntry(x: Double($0.0) + startX, y: $0.1) },
            label: label
        )
        dataSet.drawCircleHoleEnabled = false
        dataSet.drawCirclesEnabled = false
        dataSet.drawHorizontalHighlightIndicatorEnabled = false
        dataSet.lineWidth = 3
        dataSet.drawFilledEnabled = fillOpacity != 0
        #if os(OSX)
        dataSet.fillColor = NSColor(color.opacity(fillOpacity))
        dataSet.colors = [NSColor(color)]
        #elseif os(iOS)
        dataSet.fillColor = UIColor(color.opacity(fillOpacity))
        dataSet.colors = [UIColor(color)]
        #endif
        return dataSet
    }
}

extension ScatterChartDataSet {
    static func dataSet(values: [(Double, Double)], label: String, color: Color, xScale: Double = 1) -> ScatterChartDataSet {
        let dataSet = ScatterChartDataSet(
            entries: values.map { ChartDataEntry(x: Double($0.0) * xScale, y: $0.1) },
            label: label
        )
        #if os(OSX)
        dataSet.colors = [NSColor(color)]
        #elseif os(iOS)
        dataSet.colors = [UIColor(color)]
        #endif
        dataSet.setScatterShape(.circle)
        dataSet.scatterShapeSize = 4
        return dataSet
    }
}

struct AxisWeighting {
    let startIndex: Int
    let weighting: Double
}

extension Array where Element == AxisWeighting {
    
    static var `default`: [AxisWeighting] = [
        .init(startIndex: 0, weighting: 1000),
        .init(startIndex: 30, weighting: 500),
        .init(startIndex: 60, weighting: 200),
        .init(startIndex: 5 * 60, weighting: 100),
        .init(startIndex: 20 * 60, weighting: 50),
        .init(startIndex: 3600, weighting: 25),
    ]
}

extension Array where Element == Double {
    
    func nonlinearXAxis(
        minimumSpacing: Double,
        weightings: [AxisWeighting] = .default
    ) -> [(values: (x: Double, y: Double), originalX: Double)] {
        
        var xValue: Double = 0
        var lastXValue = xValue
        
        var newValues = [((Double, Double), Double)]()
        var unhandledLength = self.count
        var totalWeigth: Double = 0
        for weight in weightings.sorted(by: { $0.startIndex > $1.startIndex }) {
            guard weight.startIndex < unhandledLength else {
                continue
            }
            let numberOfValuesInStep = unhandledLength - weight.startIndex
            unhandledLength = unhandledLength - numberOfValuesInStep
            totalWeigth = Double(numberOfValuesInStep) * weight.weighting
        }
        
        for (index, weight) in weightings.enumerated() {
            let stepSize = weight.weighting / totalWeigth
            if index + 1 < weightings.count {
                let nextStep = weightings[index + 1]
                for i in weight.startIndex..<nextStep.startIndex {
                    guard i < self.count else { break }
                    if xValue - lastXValue >= minimumSpacing {
                        newValues.append(
                            (
                                (xValue, Double(self[i])),
                                Double(i)
                            )
                        )
                        lastXValue = xValue
                    }
                    xValue += stepSize
                }
            } else {
                guard weight.startIndex < self.count else { break }
                for i in weight.startIndex..<self.count {
                    if xValue - lastXValue >= minimumSpacing {
                        newValues.append(
                            (
                                (xValue, Double(self[i])),
                                Double(i)
                            )
                        )
                        lastXValue = xValue
                    }
                    xValue += stepSize
                }
            }
        }
        return newValues
    }
}

class TimeAxisValueFormatter: AxisValueFormatter {
    
    let scale: Double
    let formatter: DateComponentsFormatter
    
    init(scale: Double = 1, formatter: DateComponentsFormatter? = nil) {
        self.scale = scale
        if let formatter = formatter {
            self.formatter = formatter
        } else {
            self.formatter = DateComponentsFormatter()
            self.formatter.allowedUnits = [.hour, .minute, .second]
        }
    }
    
    func stringForValue(_ value: Double, axis: AxisBase?) -> String {
        let scaledValue = value * scale
        return formatter.string(from: scaledValue) ?? ""
    }
}

class CustomLabelsAxisValueFormatter: AxisValueFormatter {
    
    var labels: [String] = []
    
    init(labels: [String]) {
        self.labels = labels
    }
    
    func stringForValue(_ value: Double, axis: AxisBase?) -> String {
        
        let count = self.labels.count
        
        guard let axis = axis, count > 0 else {
            return ""
        }
        
        let factor = axis.axisMaximum / Double(count)
        
        let index = Int((value / factor).rounded())
        
        if index >= 0 && index < count {
            return self.labels[index]
        }
        return ""
    }
}

extension MeanMaximalPower.Curve {
    
    func axisFormatter(
        minimumSpacing: Double,
        weightings: [AxisWeighting] = .default) -> AxisValueFormatter {
        
        let nonLinearValues = means.map(Double.init)
            .nonlinearXAxis(
                minimumSpacing: minimumSpacing,
                weightings: weightings
            )
        
        let timeFormatter = DateComponentsFormatter()
        timeFormatter.allowedUnits = [.hour, .minute, .second]
        
        return CustomLabelsAxisValueFormatter(
            labels: nonLinearValues.map {
                timeFormatter.string(from: $0.originalX) ?? ""
            }
        )
    }
    
    func lineChartData(
        minimumSpacing: Double,
        weightings: [AxisWeighting] = .default
    ) -> LineChartData {
        
        let nonLinearValues = means.map(Double.init)
            .nonlinearXAxis(
                minimumSpacing: minimumSpacing,
                weightings: weightings
            )
        
        return LineChartData(
            dataSet:
                LineChartDataSet.dataSet(
                    values: nonLinearValues.map(\.values),
                    label: "Mean Maximum Power",
                    color: .blue
                )
        )
    }
}

extension DFAAlphaRegression {
    
    func chartData(title: String, maxDataPoints: Int, startX: Double = 0.2, endX: Double = 1, lineColor: Color = .green, dotColor: Color = .purple.opacity(0.5)) -> CombinedChartData {
        let combined = CombinedChartData()
        
        let regresion = self.regresion.regression
        
        combined.lineData = LineChartData(
            dataSet: LineChartDataSet.dataSet(
                values: [regresion.alpha + regresion.beta * startX, regresion.alpha + regresion.beta * endX],
                maxDataPoints: maxDataPoints,
                label: title,
                color: lineColor,
                xScale: endX - startX,
                fillOpacity: 0,
                startX: startX
            )
        )
        combined.scatterData = ScatterChartData(
            dataSet: ScatterChartDataSet.dataSet(
                values: self.regresion.values,
                label: "Data Points",
                color: dotColor
            )
        )
        
        return combined
    }
}
