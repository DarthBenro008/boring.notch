//
//  PluginMetadata.swift
//  customNotch
//

import Foundation

public struct PluginMetadata: Identifiable, Hashable, Sendable {
    public var id: PluginID
    public var name: String
    public var version: String
    public var author: String
    public var summary: String
    public var iconSystemName: String
    public var capabilities: PluginCapabilitySet
    public var defaultEnabled: Bool

    public init(
        id: PluginID,
        name: String,
        version: String,
        author: String,
        summary: String,
        iconSystemName: String,
        capabilities: PluginCapabilitySet = [],
        defaultEnabled: Bool = false
    ) {
        self.id = id
        self.name = name
        self.version = version
        self.author = author
        self.summary = summary
        self.iconSystemName = iconSystemName
        self.capabilities = capabilities
        self.defaultEnabled = defaultEnabled
    }
}
