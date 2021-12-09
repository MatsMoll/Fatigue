//
//  Deeplinker.swift
//  Fatigue
//
//  Created by Mats Mollestad on 31/07/2021.
//

import Foundation
import SwiftUI

extension URL {
    static var appScheme: String {
        let urlTypes = (Bundle.main.infoDictionary!["CFBundleURLTypes"] as! [[String : Any]]).first!
        return (urlTypes["CFBundleURLSchemes"] as! [String]).first!
    }
    static var connectToGarminPath: String { "device-select-resp" }
}

struct Deeplinker {
    
    let garminDeviceManager: GarminDeviceListViewModel
    
    enum Deeplink {
        case recorderPage
    }
    
    func manage(url: URL) -> Deeplink? {
        print(url)
        guard url.scheme == URL.appScheme else { return nil }
        if url.host == URL.connectToGarminPath {
            do {
                try garminDeviceManager.connect(to: url)
                return .recorderPage
            } catch {
                print(error)
            }
        }
        return nil
    }
}
