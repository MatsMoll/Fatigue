//
//  LSCTDetection.swift
//  Fatigue
//
//  Created by Mats Mollestad on 04/06/2021.
//

import SwiftUI

struct LSCTDetectionView: View {
    
    var timeFormatter: DateComponentsFormatter {
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .positional
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.zeroFormattingBehavior = .dropLeading
        return formatter
    }
    
    @Binding
    var lsctDetection: WorkoutSessionViewModel.State<LSCTDetector.Detection>
    
    var body: some View {
        switch lsctDetection {
        case .unavailable: Text("LSCT Detection - Unavailable")
        case .computing(let progress):
            VStack {
                Text("LSCT Detection")
                ProgressView("Computing", value: progress)
            }
            .padding()
        case .computed(let detection):
            
                
            HStack {
                VStack {
                    Text("Starting At")
                        .foregroundColor(.primary)
                        .font(.title2)
                    
                    Text(timeFormatter.string(from: TimeInterval(detection.frameWorkout)) ?? "Unknown")
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                .padding()
                
                Spacer()
                
                VStack {
                    Text("Mean Square Error")
                        .foregroundColor(.primary)
                        .font(.title2)
                    
                    Text("\(detection.meanSquareError) or sqrt => \(sqrt(detection.meanSquareError))")
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                .padding()
            }
            .padding()
        }
    }
}

struct LSCTDetection_Previews: PreviewProvider {
    static var previews: some View {
        LSCTDetectionView(lsctDetection: .constant(.unavailable))
    }
}
