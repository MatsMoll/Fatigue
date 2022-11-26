//
//  RunLSCTView.swift
//  Fatigue
//
//  Created by Mats Mollestad on 10/12/2021.
//

import SwiftUI

struct RunningLSCT {
    
    var startedAt: Int
    var stages: [LSCTStage]
    var stageIndex: Int
    
    var currentStage: LSCTStage? {
        guard 0..<stages.count ~= stageIndex else { return nil }
        return stages[stageIndex]
    }
}

struct RunLSCTView: View {
    
    let durationFormatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute, .second]
        return formatter
    }()
    
    @EnvironmentObject
    var recorder: ActivityRecorder
    
    @Binding
    var runningTest: RunningLSCT?
    
    var body: some View {
        if let runningTest = runningTest {
            VStack(alignment: .leading, spacing: 30) {
                Text("Run LSCT Test")
                Text(durationFormatter.string(from: TimeInterval(0)) ?? "\(0)")
            }
        }
    }
}

struct RunLSCTView_Previews: PreviewProvider {
    static var previews: some View {
        RunLSCTView(runningTest: .constant(nil))
    }
}
