//
//  PluginRegistry.swift
//  customNotch
//

import Combine
import SwiftUI
import CustomNotchPluginSDK

enum PluginRuntimeStatus: Equatable {
    case inactive
    case active
    case failed(String)
}

@MainActor
final class PluginRegistry: ObservableObject {
    static let shared = PluginRegistry()

    @Published private(set) var panels: [PluginID: PluginPanelSpec] = [:]
    @Published private(set) var liveActivities: [PluginID: PluginLiveActivitySpec] = [:]
    @Published private(set) var menuItems: [PluginMenuItem] = []
    @Published private(set) var settings: [PluginID: PluginSettingsSpec] = [:]
    @Published private(set) var statuses: [PluginID: PluginRuntimeStatus] = [:]

    private init() {}

    // MARK: - Registration (scoped by plugin)

    func setStatus(_ status: PluginRuntimeStatus, for id: PluginID) {
        statuses[id] = status
    }

    func registerPanel(_ spec: PluginPanelSpec, for id: PluginID) {
        panels[id] = spec
    }

    func registerLiveActivity(_ spec: PluginLiveActivitySpec, for id: PluginID) {
        liveActivities[id] = spec
    }

    func registerMenuItems(_ items: [PluginMenuItem], for id: PluginID) {
        // Replace previous items from this plugin (id-prefixed)
        menuItems.removeAll { $0.id.hasPrefix(id.rawValue + ".") || $0.id == id.rawValue }
        let namespaced = items.map { item -> PluginMenuItem in
            let itemId = item.id.contains(".") ? item.id : "\(id.rawValue).\(item.id)"
            return PluginMenuItem(
                id: itemId,
                title: item.title,
                systemImage: item.systemImage,
                isEnabled: item.isEnabled,
                action: item.action
            )
        }
        menuItems.append(contentsOf: namespaced)
    }

    func registerSettings(_ spec: PluginSettingsSpec, for id: PluginID) {
        settings[id] = spec
    }

    func clearSurfaces(for id: PluginID) {
        panels.removeValue(forKey: id)
        liveActivities.removeValue(forKey: id)
        settings.removeValue(forKey: id)
        menuItems.removeAll { $0.id.hasPrefix(id.rawValue + ".") || $0.id == id.rawValue }
    }

    // MARK: - Queries

    var orderedPanels: [(PluginID, PluginPanelSpec)] {
        panels.sorted { $0.value.sortOrder < $1.value.sortOrder }
    }

    func panelView(for id: PluginID) -> AnyView? {
        panels[id]?.makeView()
    }

    /// Highest-priority active live activity, if any.
    func activeLiveActivity() -> (PluginID, PluginLiveActivitySpec)? {
        liveActivities
            .filter { $0.value.isActive() }
            .max { $0.value.priority < $1.value.priority }
            .map { ($0.key, $0.value) }
    }
}
