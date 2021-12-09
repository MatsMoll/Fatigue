//
//  View+roundedButton.swift
//  View+roundedButton
//
//  Created by Mats Mollestad on 04/09/2021.
//

import SwiftUI

extension View {
    func roundedButton(color: Color) -> some View {
        self.padding()
            .background(color)
            .cornerRadius(10)
    }
}
