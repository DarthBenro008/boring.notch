//
//  PluginID.swift
//  customNotch
//

import Foundation

/// Reverse-DNS identifier for a plugin, e.g. `custom.notch.plugin.hello`.
public struct PluginID: Hashable, Codable, RawRepresentable, Sendable, CustomStringConvertible {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    public init(_ rawValue: String) {
        self.rawValue = rawValue
    }

    public var description: String { rawValue }
}
