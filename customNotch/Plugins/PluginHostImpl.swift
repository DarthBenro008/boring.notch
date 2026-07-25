//
//  PluginHostImpl.swift
//  customNotch
//

import Foundation
import SwiftUI

@MainActor
final class PluginHostImpl: PluginHost {
    let pluginID: PluginID
    let logger: PluginLogger
    let storage: PluginStorage

    private weak var manager: PluginManager?
    private var handlers: [UUID: @MainActor (HostEvent) -> Void] = [:]

    init(pluginID: PluginID, manager: PluginManager) {
        self.pluginID = pluginID
        self.manager = manager
        self.logger = PluginLogger(pluginID: pluginID)
        self.storage = PluginStorage(pluginID: pluginID)
    }

    func subscribe(handler: @escaping @MainActor (HostEvent) -> Void) -> PluginEventSubscription {
        let token = UUID()
        handlers[token] = handler
        return PluginEventSubscription { [weak self] in
            Task { @MainActor in
                self?.handlers.removeValue(forKey: token)
            }
        }
    }

    func deliver(_ event: HostEvent) {
        for handler in handlers.values {
            handler(event)
        }
    }

    func registerPanel(_ spec: PluginPanelSpec) {
        PluginRegistry.shared.registerPanel(spec, for: pluginID)
    }

    func registerLiveActivity(_ spec: PluginLiveActivitySpec) {
        PluginRegistry.shared.registerLiveActivity(spec, for: pluginID)
    }

    func registerMenuItems(_ items: [PluginMenuItem]) {
        PluginRegistry.shared.registerMenuItems(items, for: pluginID)
    }

    func registerSettings(_ spec: PluginSettingsSpec) {
        PluginRegistry.shared.registerSettings(spec, for: pluginID)
    }

    func showSneakPeek(_ peek: PluginSneakPeek) {
        CustomViewCoordinator.shared.togglePluginSneakPeek(
            title: peek.title,
            systemImage: peek.systemImage,
            value: peek.value ?? 0,
            duration: peek.duration
        )
    }

    func openNotch(to panel: PluginID?) {
        manager?.openNotch(to: panel ?? pluginID)
    }

    func closeNotch() {
        manager?.closeNotch()
    }
}
