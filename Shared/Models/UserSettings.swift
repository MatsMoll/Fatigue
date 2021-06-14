//
//  UserSettings.swift
//  Fatigue
//
//  Created by Mats Mollestad on 09/06/2021.
//

import Foundation
import OSLog

struct UserSettings: Codable {
    
    var ftp: Int?
    
    var artifactCorrection: Double = 0.05
    
    var dfaWindow: TimeInterval = 120
}
