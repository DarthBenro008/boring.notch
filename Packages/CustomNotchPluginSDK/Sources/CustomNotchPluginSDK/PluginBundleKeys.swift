//
//  PluginBundleKeys.swift
//  CustomNotchPluginSDK
//

import Foundation

/// Info.plist keys for `.cnplugin` bundles (third-party).
public enum PluginBundleKeys {
    public static let principalClass = "CNPluginPrincipalClass"
    public static let sdkVersion = "CNPluginSDKVersion"
    public static let minHostVersion = "CNPluginMinHostVersion"
    public static let capabilities = "CNPluginCapabilities"
    public static let summary = "CNPluginSummary"
    public static let author = "CNPluginAuthor"
    public static let iconSystemName = "CNPluginIconSystemName"

    /// Recommended path component under Application Support.
    public static let applicationSupportFolderName = "custom.notch"
    public static let pluginsFolderName = "Plugins"
    public static let bundleExtension = "cnplugin"
}
