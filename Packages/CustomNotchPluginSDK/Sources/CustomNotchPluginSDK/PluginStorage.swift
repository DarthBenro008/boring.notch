//
//  PluginStorage.swift
//  customNotch
//

import Foundation

/// Isolated key-value storage for a single plugin.
public final class PluginStorage: @unchecked Sendable {
    private let defaults: UserDefaults
    private let prefix: String

    public init(pluginID: PluginID) {
        self.prefix = "plugin.\(pluginID.rawValue)."
        // Use standard defaults with namespaced keys (simple + reliable under sandbox).
        self.defaults = .standard
    }

    public func string(forKey key: String) -> String? {
        defaults.string(forKey: prefix + key)
    }

    public func set(_ value: String?, forKey key: String) {
        defaults.set(value, forKey: prefix + key)
    }

    public func bool(forKey key: String, default defaultValue: Bool = false) -> Bool {
        let full = prefix + key
        if defaults.object(forKey: full) == nil { return defaultValue }
        return defaults.bool(forKey: full)
    }

    public func set(_ value: Bool, forKey key: String) {
        defaults.set(value, forKey: prefix + key)
    }

    public func double(forKey key: String, default defaultValue: Double = 0) -> Double {
        let full = prefix + key
        if defaults.object(forKey: full) == nil { return defaultValue }
        return defaults.double(forKey: full)
    }

    public func set(_ value: Double, forKey key: String) {
        defaults.set(value, forKey: prefix + key)
    }

    public func removeValue(forKey key: String) {
        defaults.removeObject(forKey: prefix + key)
    }
}
