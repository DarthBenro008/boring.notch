//
//  CustomNotchPlugin.swift
//  customNotch
//

import Foundation

/// Contract every Custom Notch plugin must implement.
@MainActor
public protocol CustomNotchPlugin: AnyObject {
    static var metadata: PluginMetadata { get }

    init()

    func activate(host: PluginHost) async
    func deactivate() async
}

/// Host services exposed to a plugin for the duration of its activation.
@MainActor
public protocol PluginHost: AnyObject {
    var pluginID: PluginID { get }
    var logger: PluginLogger { get }
    var storage: PluginStorage { get }

    /// Subscribe to host lifecycle / environment events.
    func subscribe(handler: @escaping @MainActor (HostEvent) -> Void) -> PluginEventSubscription

    func registerPanel(_ spec: PluginPanelSpec)
    func registerLiveActivity(_ spec: PluginLiveActivitySpec)
    func registerMenuItems(_ items: [PluginMenuItem])
    func registerSettings(_ spec: PluginSettingsSpec)

    func showSneakPeek(_ peek: PluginSneakPeek)
    func openNotch(to panel: PluginID?)
    func closeNotch()
}

/// Opaque token for cancelling an event subscription.
public final class PluginEventSubscription {
    private let cancelHandler: () -> Void
    private var cancelled = false

    public init(cancel: @escaping () -> Void) {
        self.cancelHandler = cancel
    }

    public func cancel() {
        guard !cancelled else { return }
        cancelled = true
        cancelHandler()
    }

    deinit {
        cancel()
    }
}
