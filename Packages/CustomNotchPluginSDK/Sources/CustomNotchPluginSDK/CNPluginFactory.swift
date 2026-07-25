//
//  CNPluginFactory.swift
//  CustomNotchPluginSDK
//
//  ObjC-visible entry point so the host can load third-party .cnplugin bundles
//  via Bundle + principal class without relying on Swift name mangling.
//

import Foundation

/// Base class for plugin bundle entry points.
///
/// Third-party plugins subclass this, override `createPlugin()`, and list the
/// subclass name in `CNPluginPrincipalClass` inside the bundle’s Info.plist.
///
/// First-party (compiled-in) plugins do not need a factory; they register types
/// directly with `PluginManager`.
@objc(CNPluginFactory)
open class CNPluginFactory: NSObject {
    /// Create a new plugin instance. Host retains it for the activation lifetime.
    @objc open class func createPlugin() -> Any {
        fatalError("CNPluginFactory.createPlugin() must be overridden by the plugin")
    }

    /// Typed helper for Swift callers.
    public class func makePlugin() -> any CustomNotchPlugin {
        let value = createPlugin()
        guard let plugin = value as? any CustomNotchPlugin else {
            fatalError("createPlugin() must return a CustomNotchPlugin instance, got \(type(of: value))")
        }
        return plugin
    }
}
