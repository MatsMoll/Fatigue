//
//  Image+SFSymbol.swift
//  Fatigue
//
//  Created by Mats Mollestad on 11/06/2021.
//

import Foundation
import SwiftUI

struct SFSymbol: ExpressibleByStringLiteral {
    let name: String
    
    init(stringLiteral value: String) {
        self.name = value
    }
    
    static let boltFill: SFSymbol = "bolt.fill"
    static let bolt: SFSymbol = "bolt"
    static let figureWalk: SFSymbol = "figure.walk"
    static let recordCircle: SFSymbol = "record.circle"
    
    static let gearshapeFill: SFSymbol = "gearshape.fill"
    static let crossFill: SFSymbol = "cross.fill"
    static let heartFill: SFSymbol = "heart.fill"
    
    static let checkmark: SFSymbol = "checkmark"
    
    static let pauseFill: SFSymbol = "pause.fill"
    static let playFill: SFSymbol = "play.fill"
    static let stopCircleFill: SFSymbol = "stop.circle.fill"
    
    static let skew: SFSymbol = "skew"
    static let waveformPathEcg: SFSymbol = "waveform.path.ecg"
    
    static let goForwared: SFSymbol = "goforward"
    
    static let clock: SFSymbol = "clock"
    
    static let sum: SFSymbol = "sum"
    
    static let arrowUp: SFSymbol = "arrow.up"
    static let arrowDown: SFSymbol = "arrow.down"
    static let arrowRight: SFSymbol = "arrow.right"
    
    static let handThumbsup: SFSymbol = "hand.thumbsup"
    static let handThumbsupFill: SFSymbol = "hand.thumbsup.fill"
    
    static let lineHorizontalThree: SFSymbol = "line.horizontal.3"
    
    static let arrowtriangleAndLineVertical: SFSymbol = "arrowtriangle.right.fill.and.line.vertical.and.arrowtriangle.left.fill"
}

extension Label where Title == Text, Icon == Image {
    init(_ label: String, symbol: SFSymbol) {
        self.init(label, systemImage: symbol.name)

    }
}

extension Image {
    init(symbol: SFSymbol) {
        self.init(systemName: symbol.name)
    }
}
