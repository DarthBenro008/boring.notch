//
//  PluginCapability.swift
//  CustomNotchPluginSDK
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

    /// Parse comma/space-separated tokens from Info.plist (e.g. "network,wifiSSID").
    public static func parseManifestList(_ string: String?) -> PluginCapabilitySet {
        guard let string, !string.isEmpty else { return [] }
        var set: PluginCapabilitySet = []
        let tokens = string
            .split { $0 == "," || $0 == " " || $0 == ";" || $0 == "\n" }
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }
            .filter { !$0.isEmpty }
        for token in tokens {
            switch token {
            case "network": set.insert(.network)
            case "wifissid", "wifi_ssid", "wifi-ssid": set.insert(.wifiSSID)
            case "notifications", "notification": set.insert(.notifications)
            case "localnetwork", "local_network", "local-network": set.insert(.localNetwork)
            default: break
            }
        }
        return set
    }

    public var manifestString: String {
        var parts: [String] = []
        if contains(.network) { parts.append("network") }
        if contains(.wifiSSID) { parts.append("wifiSSID") }
        if contains(.notifications) { parts.append("notifications") }
        if contains(.localNetwork) { parts.append("localNetwork") }
        return parts.joined(separator: ",")
    }
}
