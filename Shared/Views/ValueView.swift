//
//  ValueView.swift
//  Fatigue
//
//  Created by Mats Mollestad on 10/06/2021.
//

import SwiftUI

struct ValueView: View {
    
    let title: String
    let value: String
    
    var systemImage: String? = nil
    var imageColor: Color = .clear
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            if let systemImage = systemImage {
                HStack {
                    Image(systemName: systemImage)
                        .foregroundColor(imageColor)
                    
                    Text(title) 
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                    
            } else {
                Text(title)
                    .font(.body)
                    .foregroundColor(.secondary)
            }

            Text(value)
                .font(.title2.weight(.medium))
                .foregroundColor(.primary)
        }
        .frame(alignment: .leading)
    }
}

extension ValueView {
    init(title: String, value: String, symbol: SFSymbol, imageColor: Color = .clear) {
        self.init(
            title: title,
            value: value,
            systemImage: symbol.name,
            imageColor: imageColor
        )
    }
}

struct ValueView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ValueView(
                title: "Arobic Threshold",
                value: "240 watts"
            )
            
            ValueView(
                title: "Arobic Threshold",
                value: "240 watts",
                symbol: .heartFill,
                imageColor: .red
            )
        }
        .previewLayout(PreviewLayout.fixed(width: 300, height: 100))
    }
}
