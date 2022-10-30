//
//  RecorderControllsView.swift
//  RecorderControllsView
//
//  Created by Mats Mollestad on 04/09/2021.
//

import SwiftUI

struct ControllAction: View {
    
    let symbol: SFSymbol
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action, label: {
            VStack {
                Image(symbol: symbol)
                    .font(.title)
                
                Text(title)
            }
        })
        .roundedButton(color: .init(.secondarySystemBackground))
    }
}

struct RecorderControllsView: View {
    
    @EnvironmentObject
    var recoder: ActivityRecorder
    
    @Binding
    var shouldSave: Bool
    
    var body: some View {
        ControllAction(
            symbol: recoder.isRecording ? .pauseFill : .playFill,
            title: recoder.isRecording ? "Pause" : "Start",
            action: recoder.isRecording ? recoder.pauseRecording : recoder.startRecording
        )
        
        if recoder.hasValues {
            ControllAction(
                symbol: .stopCircleFill,
                title: "Stop",
                action: saveActivity
            )
        }
    }
    
    func saveActivity() {
        recoder.pauseRecording()
        shouldSave = true
    }
}

struct RecorderControllsView_Previews: PreviewProvider {
    static var previews: some View {
        RecorderControllsView(shouldSave: .constant(false))
            .environmentObject(ActivityRecorder())
    }
}
