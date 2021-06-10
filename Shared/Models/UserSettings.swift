//
//  UserSettings.swift
//  Fatigue
//
//  Created by Mats Mollestad on 09/06/2021.
//

import Foundation

class UserSettings: ObservableObject {
    
    @Published
    var ftp: Int?
    
    init(ftp: Int? = nil) {
        self.ftp = ftp
    }
}
