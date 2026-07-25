//
//  PluginSDKVersion.swift
//  CustomNotchPluginSDK
//

import Foundation

/// Semantic compatibility for third-party plugins.
///
/// - Major must match the host’s supported major (breaking API changes).
/// - Minor/patch are informational for tooling and release notes.
public enum PluginSDKVersion {
    /// Bump on breaking host API / surface contract changes.
    public static let major: Int = 1
    public static let minor: Int = 0
    public static let patch: Int = 0

    public static var string: String { "\(major).\(minor).\(patch)" }

    /// Info.plist key plugins should set: integer major only.
    public static let infoPlistMajorKey = "CNPluginSDKVersion"

    public static func isCompatible(pluginMajor: Int) -> Bool {
        pluginMajor == major
    }
}
