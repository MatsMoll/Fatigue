//
//  LSCTDetection.swift
//  Fatigue
//
//  Created by Mats Mollestad on 04/06/2021.
//

import SwiftUI

struct LSCTDetectionView: View {
    
    static let timeFormatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .positional
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.zeroFormattingBehavior = .dropLeading
        return formatter
    }()
    
    static let numberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 0
        return formatter
    }()
    
    @EnvironmentObject var viewModel: WorkoutSessionViewModel
    
    #if os(iOS)
    @Environment(\.horizontalSizeClass)
    var sizeClass
    #endif
    
    var body: some View {
        AsyncContentView(
            value: viewModel.lsctDetection
        ) {
            viewModel.detectLSCT()
        } content: { detection in
            #if os(iOS)
            if sizeClass == .compact {
                compactValues(detection: detection)
            } else {
                largeValues(detection: detection)
            }
            #elseif os(OSX)
            largeValues(detection: detection)
            #endif
        }
    }
    
    @ViewBuilder
    func compactValues(detection: LSCTDetector.Detection) -> some View {
        ValueView(
            title: "Starting At",
            value: Self.timeFormatter.string(from: TimeInterval(detection.frameWorkout)) ?? "Unknown"
        )
        
        ValueView(
            title: "Mean Square Error",
            value: "\(Int(detection.meanSquareError))"
        )
    }
    
    @ViewBuilder
    func largeValues(detection: LSCTDetector.Detection) -> some View {
        HStack {
            ValueView(
                title: "Starting At",
                value: Self.timeFormatter.string(from: TimeInterval(detection.frameWorkout)) ?? "Unknown"
            )
            
            Spacer()
            
            ValueView(
                title: "Mean Square Error",
                value: Self.numberFormatter.string(from: .init(value: detection.meanSquareError)) ?? "0"
            )
        }
    }
}

struct LSCTDetection_Previews: PreviewProvider {
    static var previews: some View {
        LSCTDetectionView()
    }
}
