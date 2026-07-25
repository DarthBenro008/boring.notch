//
//  HostEvent.swift
//  customNotch
//

import Foundation

public enum HostEvent: Sendable {
    case didLaunch
    case willTerminate
    case notchDidOpen
    case notchDidClose
    case preferredDisplayChanged(uuid: String?)
    case networkPathChanged(isSatisfied: Bool)
    case wifiSSIDChanged(ssid: String?)
    case tick(Date)
}
