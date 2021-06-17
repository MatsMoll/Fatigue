//
//  LSCTResultView.swift
//  Fatigue
//
//  Created by Mats Mollestad on 14/06/2021.
//

import SwiftUI

struct TrainingMetricDefinition {
    let metric: String
    let unit: String?
    let description: String
    let symbol: SFSymbol
    let color: Color
    
    static let power = TrainingMetricDefinition(
        metric: "Power",
        unit: "watts",
        description: "The amount of work done",
        symbol: .boltFill,
        color: .blue
    )
    
    static let heartRate = TrainingMetricDefinition(
        metric: "Heart Rate",
        unit: "bpm",
        description: "How fast a heart is beating",
        symbol: .heartFill,
        color: .red
    )
    
    static let cadence = TrainingMetricDefinition(
        metric: "Cadence",
        unit: "rpm",
        description: "How fast the pedals turn",
        symbol: .goForwared,
        color: .green
    )
    
    static let dfaAlpha1 = TrainingMetricDefinition(
        metric: "DFA Alpha 1",
        unit: nil,
        description: "How much long term and short term randomnes there is between all heart beats variations",
        symbol: .heartFill,
        color: .purple
    )
}

struct LSCTResultViewModel {
    
    static let numberFormatter: NumberFormatter = .defaultFormatter
    static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
    static let timeComponentFormatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.unitsStyle = .abbreviated
        return formatter
    }()
    
    struct SubresultViewModel {
        let value: String
        let development: String
        let symbol: SFSymbol
        let color: Color
    }
    
    let lsctResult: LSCTResult
    
    var lsctIdentifierDescription: String {
        "Detected LSCT at \(Self.timeComponentFormatter.string(from: TimeInterval(lsctResult.runIdentifer.startingAt)) ?? "00:00"), and using baseline from \(Self.dateFormatter.string(from: lsctResult.baselineRunIdentifier.workoutDate)) starting at \(Self.timeComponentFormatter.string(from: TimeInterval(lsctResult.baselineRunIdentifier.startingAt)) ?? "00:00")"
    }
    
    private var groupedValues: [(TrainingMetricDefinition, LSCTResult.Subresult?)] {
        [
            (.power, lsctResult.power),
            (.cadence, lsctResult.cadence),
            (.dfaAlpha1, lsctResult.dfaAlpha1),
            (.heartRate, lsctResult.heartRate?.lastStageDiff),
        ]
    }
    
    private var unwrapedValues: [(TrainingMetricDefinition, LSCTResult.Subresult)] {
        groupedValues.compactMap { (metric, subresult) in
            guard let subresult = subresult else { return nil }
            return (metric, subresult)
        }
    }
    
    private var developmentSummary: Int {
        unwrapedValues.map(\.1).reduce(0) { sum, subresult in
            switch subresult.development {
            case .significantBetter: return sum + 1
            case .significantWorse: return sum - 1
            case .insignificant: return sum
            }
        }
    }
    
    var positiveDevelopments: [SubresultViewModel] {
        // FIXME: -- Is not correct
        unwrapedValues.filter { $0.1.development == .significantBetter }
            .map { (metric, subresult) in
                SubresultViewModel(
                    value: metric.metric,
                    development: Self.numberFormatter.string(from: .init(value: subresult.absoluteDifferance)) ?? "\(subresult.absoluteDifferance)",
                    symbol: metric.symbol,
                    color: metric.color
                )
            }
    }
    
    var negativeDevelopments: [SubresultViewModel] {
        // FIXME: -- Is not correct
        unwrapedValues.filter { $0.1.development == .significantWorse }
            .map { (metric, subresult) in
                SubresultViewModel(
                    value: metric.metric,
                    development: Self.numberFormatter.string(from: .init(value: subresult.absoluteDifferance)) ?? "\(subresult.absoluteDifferance)",
                    symbol: metric.symbol,
                    color: metric.color
                )
            }
    }
    
    var summarySymbol: SFSymbol {
        if developmentSummary > 1 {
            return .arrowUp
        } else if developmentSummary < -1 {
            return .arrowDown
        } else {
            return .lineHorizontalThree
        }
    }
    
    var summarySymbolColor: Color {
        if developmentSummary > 1 {
            return .green
        } else if developmentSummary < -1 {
            return .orange
        } else {
            return .secondary
        }
    }
    
    var summaryText: String {
        if developmentSummary > 1 {
            return "Looking Good"
        } else if developmentSummary < -1 {
            return "Be carefull"
        } else {
            return "Looking normal"
        }
    }
}

struct LSCTResultView: View {
    
    let lsctResult: LSCTResultViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 30) {
            
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Image(symbol: lsctResult.summarySymbol)
                        .font(.title.bold())
                        .foregroundColor(lsctResult.summarySymbolColor)
                    
                    Text(lsctResult.summaryText)
                        .font(.title.bold())
                        .foregroundColor(.primary)
                }
                
                Text(lsctResult.lsctIdentifierDescription)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            if lsctResult.positiveDevelopments.isEmpty == false {
                VStack(alignment: .leading, spacing: 10) {
                    Label("Positive Development", symbol: .arrowUp)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    ForEach(lsctResult.positiveDevelopments, id: \.value) { model in
                        ValueView(
                            title: model.value,
                            value: "\(model.development)",
                            symbol: model.symbol,
                            imageColor: model.color
                        )
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
            
            if lsctResult.negativeDevelopments.isEmpty == false {
                VStack(alignment: .leading, spacing: 10) {
                    Label("Unwanted Development", symbol: .arrowDown)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    ForEach(lsctResult.negativeDevelopments, id: \.value) { model in
                        ValueView(
                            title: model.value,
                            value: "\(model.development)",
                            symbol: model.symbol,
                            imageColor: model.color
                        )
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
        }
    }
}


struct LSCTResultView_Previews: PreviewProvider {
    static var previews: some View {
        LSCTResultView(lsctResult: .init(lsctResult: .testData))
            .preferredColorScheme(.dark)
    }
}


extension LSCTResult {
    static let testData = LSCTResult(
        power: LSCTResult.Subresult(relativDifferance: 13, absoluteDifferance: 13, development: .significantBetter),
        cadence: LSCTResult.Subresult(relativDifferance: 3, absoluteDifferance: 3, development: .significantWorse),
        dfaAlpha1: LSCTResult.Subresult(relativDifferance: 0.01, absoluteDifferance: 0.01, development: .significantBetter),
        heartRate: HeartRateSubresults(
            lastStageDiff: LSCTResult.Subresult(relativDifferance: -5, absoluteDifferance: -5, development: .significantBetter),
            intensityResponse: LinearRegression.Result(alpha: 3, beta: 0),
            hrrAnalysis: LSCTResult.Subresult(relativDifferance: 2, absoluteDifferance: 2, development: .significantBetter)
        ),
        baselineRunIdentifier: .init(
            startingAt: 500,
            workoutDate: .init()
        ),
        runIdentifer: .init(
            startingAt: 32,
            workoutDate: .init()
        )
    )
}
