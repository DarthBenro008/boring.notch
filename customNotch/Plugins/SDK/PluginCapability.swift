//
//  PluginCapability.swift
//  customNotch
//

import Foundation

/// Capabilities a plugin may declare. Host gates privileged events on these flags.
public struct PluginCapabilitySet: OptionSet, Codable, Hashable, Sendable {
    public let rawValue: Int

    public init(rawValue: Int) {
        self.rawValue = rawValue
    }

    public static let network       = PluginCapabilitySet(rawValue: 1 << 0)
    public static let wifiSSID      = PluginCapabilitySet(rawValue: 1 << 1)
    public static let notifications = PluginCapabilitySet(rawValue: 1 << 2)
    public static let localNetwork  = PluginCapabilitySet(rawValue: 1 << 3)

    public var displayNames: [String] {
        var names: [String] = []
        if contains(.network) { names.append("Network") }
        if contains(.wifiSSID) { names.append("Wi‑Fi SSID") }
        if contains(.notifications) { names.append("Notifications") }
        if contains(.localNetwork) { names.append("Local Network") }
        return names
    }
}
