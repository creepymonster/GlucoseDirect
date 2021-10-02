//
//  DeviceInfo.swift
//  LibreDirect
//
//  Created by Reimar Metzen on 02.10.21.
//

import Foundation

public struct DeviceInfo: Codable {
    let battery: String
    let hardwareVersion: String
    let firmwareVersion: String
    let manufacturer: String
    let productName: String
}
