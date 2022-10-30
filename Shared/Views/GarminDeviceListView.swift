//
//  GarminDeviceListView.swift
//  Fatigue (iOS)
//
//  Created by Mats Mollestad on 31/07/2021.
//

#if os(iOS)
import SwiftUI
import Combine

//enum GarminError: Error {
//    case missingID(deviceName: String)
//}
//
//class GarminDeviceListViewModel: NSObject, ObservableObject {
//    
//    let urlScheme: String
//    
//    lazy var connectIQ: ConnectIQ = {
//        let connectIQ = ConnectIQ.sharedInstance()!
//        print(urlScheme)
//        connectIQ.initialize(withUrlScheme: urlScheme, uiOverrideDelegate: nil)
//        
//        return connectIQ
//    }()
//    
//    var connectedDevices: [UUID : IQDevice] = [:]
//    
//    let appUuid = UUID(uuidString: "1b245748-27b0-4824-a56c-1a2ed8282d59")!
//    
//    init(urlScheme: String = URL.appScheme) {
//        self.urlScheme = urlScheme
//    }
//    
//    func selectDevice() {
//        // Workaround as the `connectIQ.showDeviceSelection()` won't work
//        let url = URL(string: "gcm-ciq://device-select-req?ciqApp=Fatigue&ciqBundle=com.mollestad.rested&ciqScheme=rested&ciqSdkVersion=10000")!
//        UIApplication.shared.open(url, options: [:], completionHandler: nil)
//    }
//    
//    func connect(to deviceUrl: URL) throws {
//        // Over to connect iq app and returns a device on launch with options
//        guard let someDevice = connectIQ.parseDeviceSelectionResponse(from: deviceUrl) else {
//            
//            return
//        }
//        connectedDevices = [:]
//        for device in someDevice {
//            guard var garminDevice = device as? IQDevice else { continue }
//            
//            if garminDevice.uuid == nil {
//                print("Unable to parse : \(garminDevice.friendlyName)")
//                continue
//                throw GarminError.missingID(deviceName: garminDevice.friendlyName)
////                garminDevice = IQDevice(
////                    id: UUID(uuidString: "8510EF27-DBB5-0E7C-1D7E-2726325F1941")!,
////                    modelName: garminDevice.modelName,
////                    friendlyName: garminDevice.friendlyName
////                )
//            }
//            if let deviceID = garminDevice.uuid {
//                self.connectedDevices[deviceID] = garminDevice
//            }
//            connectIQ.register(forDeviceEvents: garminDevice, delegate: self)
//        }
//    }
//    
//    func appStatus(for device: UUID) {
//        guard let device = connectedDevices[device] else { return }
//        let app = IQApp(uuid: appUuid, store: appUuid, device: device)
//        connectIQ.getAppStatus(app) { appStatus in
//            print("App Status: \(appStatus)")
//        }
//    }
//    
//    func sendMessage(to app: IQApp) {
//        connectIQ.sendMessage("Test", to: app) { sent, total in
//            print("Progress: \(sent / total)")
//        } completion: { messageResult in
//            print(messageResult)
//        }
//    }
//    
//    func app(for device: IQDevice) -> IQApp {
//        return IQApp(uuid: appUuid, store: appUuid, device: device)
//    }
//    
//    func send<T: Codable>(message: T, to device: IQDevice) {
//        let jsonData = try! JSONEncoder().encode(message)
//        let jsonString = String(data: jsonData, encoding: .utf8)
//        let app = app(for: device)
//        connectIQ.sendMessage(jsonString, to: app) { sent, total in
//            print("Progress: \(sent / total)")
//        } completion: { messageResult in
//            print(NSStringFromSendMessageResult(messageResult))
//        }
//    }
//    
//    func send<T: Codable>(message: T) {
////        for device in connectedDevices.frames {
////            send(message: message, to: device)
////        }
//    }
//}
//
//extension GarminDeviceListViewModel: IQDeviceEventDelegate {
//    func deviceStatusChanged(_ device: IQDevice!, status: IQDeviceStatus) {
//        print("Status for device: \(device.uuid) changed to \(status)")
//        switch status {
//        case .connected:
//            print("Connected to device")
//            
//        case .bluetoothNotReady: print("bluetoothNotReady")
//        case .invalidDevice: print("Invalid Device")
//        case .notConnected: print("Not connected")
//        case .notFound: print("Not Found")
//        }
//    }
//}
//
//struct GarminDeviceListView: View {
//    
//    
//    
//    var body: some View {
//        List {
//            Text("")
//        }
//    }
//}

#endif
