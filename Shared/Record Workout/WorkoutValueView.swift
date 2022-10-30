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
        tintColor: .red
    )
}

struct WorkoutValueView: View {
    
    let type: WorkoutValueType
    let value: String
    
    @Environment(\.horizontalSizeClass)
    var horizontalSizeClass
    
    var valueFont: Font {
        if horizontalSizeClass == .regular {
            return .largeTitle.bold()
        } else {
            return .title2.bold()
        }
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
