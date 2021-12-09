//
//  Power Meter Handler.swift
//  Power Meter Handler
//
//  Created by Mats Mollestad on 04/09/2021.
//

import Foundation
import Combine

protocol PowerMeterHandler: BluetoothHandler {
    var powerListner: AnyPublisher<PowerDeviceValue, Never> { get }
}
