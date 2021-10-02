//
//  Bubble.swift
//  LibreDirect
//
//  Created by Reimar Metzen on 30.09.21.
//  Used code from dabear, https://github.com/dabear/LibreTransmitter/blob/main/Bluetooth/Transmitter/BubbleTransmitter.swift
//

import Foundation
import Combine
import CoreBluetooth

public func bubbleMiddelware() -> Middleware<AppState, AppAction> {
    return deviceMiddelware(service: BubbleService())
}
