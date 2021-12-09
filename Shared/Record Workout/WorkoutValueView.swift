//
//  WorkoutValueView.swift
//  WorkoutValueView
//
//  Created by Mats Mollestad on 04/09/2021.
//

import SwiftUI

struct WorkoutValueType {
    let name: String
    let unit: String?
    let symbol: SFSymbol
    let tintColor: Color
    
    var average: WorkoutValueType {
        .init(name: "Average \(name)", unit: unit, symbol: symbol, tintColor: tintColor)
    }
    var normalized: WorkoutValueType {
        .init(name: "Normalized \(name)", unit: unit, symbol: symbol, tintColor: tintColor)
    }
    var min: WorkoutValueType {
        .init(name: "Min \(name)", unit: unit, symbol: symbol, tintColor: tintColor)
    }
    var max: WorkoutValueType {
        .init(name: "Max \(name)", unit: unit, symbol: symbol, tintColor: tintColor)
    }
    var baseline: WorkoutValueType {
        .init(name: "Baseline \(name)", unit: unit, symbol: symbol, tintColor: tintColor.opacity(0.7))
    }
    
    func withUnits(from valueType: WorkoutValueType) -> WorkoutValueType {
        .init(name: name, unit: valueType.unit, symbol: valueType.symbol, tintColor: tintColor)
    }
}

extension WorkoutValueType {
    static let power = WorkoutValueType(
        name: "Power",
        unit: "watt",
        symbol: .boltFill,
        tintColor: .blue
    )
    static let powerBalance = WorkoutValueType(
        name: "Power Balance",
        unit: nil,
        symbol: .boltFill,
        tintColor: .blue
    )
    static let cadence = WorkoutValueType(
        name: "Cadence",
        unit: "rpm",
        symbol: .goForwared,
        tintColor: .orange
    )
    static let duration = WorkoutValueType(
        name: "Duration",
        unit: nil,
        symbol: .clock,
        tintColor: .purple
    )
    static let lapDuration = WorkoutValueType(
        name: "Lap Duration",
        unit: nil,
        symbol: .clock,
        tintColor: .purple
    )
    static let lapNumber = WorkoutValueType(
        name: "Lap",
        unit: nil,
        symbol: .goForwared,
        tintColor: .purple
    )
    static let heartRate = WorkoutValueType(
        name: "Heart Rate",
        unit: "bpm",
        symbol: .heartFill,
        tintColor: .red
    )
    static let dfaAlpha1 = WorkoutValueType(
        name: "DFA Alpha 1",
        unit: nil,
        symbol: .heartFill,
        tintColor: .purple
    )
    static let hrr = WorkoutValueType(
        name: "Heart Rate Recovery",
        unit: "Δbpm/s",
        symbol: .heartFill,
        tintColor: .purple
    )
    static let intensityResponse = WorkoutValueType(
        name: "Intensity Response",
        unit: "Δbpm/s",
        symbol: .heartFill,
        tintColor: .purple
    )
    
    static let anarobicThreshold = WorkoutValueType(
        name: "Anarobic Threshold",
        unit: "",
        symbol: .heartFill,
        tintColor: .purple
    )
    
    static let arobicThreshold = WorkoutValueType(
        name: "Arobic Threshold",
        unit: "",
        symbol: .heartFill,
        tintColor: .purple
    )
}

struct WorkoutValueView: View {
    
    let type: WorkoutValueType
    let value: String
    
    @Environment(\.horizontalSizeClass)
    var horizontalSizeClass
    
    var valueFont: Font {
        return .title2.bold()
        // Unused for now
//        if horizontalSizeClass == .regular {
//            return .largeTitle.bold()
//        } else {
//            return .title2.bold()
//        }
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            Label(
                title: { Text(type.name.uppercased()).foregroundColor(Color.init(UIColor.secondaryLabel)) },
                icon: { Image(symbol: type.symbol).foregroundColor(type.tintColor) }
            )
            .font(.footnote)
                
            VStack(alignment: .leading) {
                if let unit = type.unit {
                    HStack(alignment: .firstTextBaseline) {
                        Text(value)
                            .font(valueFont)
                            .foregroundColor(.primary)
                            .foregroundColor(type.tintColor)
                        Text(unit)
                            .foregroundColor(.secondary)
                    }
                } else {
                    Text(value)
                        .font(valueFont)
                        .foregroundColor(.primary)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(UIColor.secondarySystemBackground))
            .cornerRadius(10)
        }
    }
}

//struct WorkoutValueView_Previews: PreviewProvider {
//    static var previews: some View {
//        WorkoutValueView()
//    }
//}
