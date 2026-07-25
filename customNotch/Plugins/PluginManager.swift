//
//  PluginManager.swift
//  customNotch
//

import Combine
import Defaults
import Foundation
import SwiftUI
import CustomNotchPluginSDK

/// Owns plugin lifecycle and built-in registration.
@MainActor
final class PluginManager: ObservableObject {
    static let shared = PluginManager()

    @Published private(set) var available: [PluginMetadata] = []
    @Published private(set) var isBootstrapped = false

    private var factories: [PluginID: () -> any CustomNotchPlugin] = [:]
    private var metadataByID: [PluginID: PluginMetadata] = [:]
    private var instances: [PluginID: any CustomNotchPlugin] = [:]
    private var hosts: [PluginID: PluginHostImpl] = [:]
    private var bootstrapTask: Task<Void, Never>?

    private init() {}

    // MARK: - Bootstrap

    func bootstrap() {
        guard !isBootstrapped else { return }
        registerBuiltIns()
        rebuildAvailable()
        isBootstrapped = true

        NetworkPathMonitorService.shared.start()
        if available.contains(where: { isEnabled($0.id) && $0.capabilities.contains(.wifiSSID) }) {
            WiFiSSIDMonitor.shared.start()
        }

        bootstrapTask = Task { @MainActor in
            for meta in available where isEnabled(meta.id) {
                await activate(meta.id)
            }
            broadcast(.didLaunch)
            // Push current network state
            broadcast(.networkPathChanged(isSatisfied: NetworkPathMonitorService.shared.isSatisfied))
            if let ssid = WiFiSSIDMonitor.shared.currentSSID {
                broadcastWiFiSSIDChanged(ssid)
            }
        }
    }

    func shutdown() {
        bootstrapTask?.cancel()
        broadcast(.willTerminate)
        NetworkPathMonitorService.shared.stop()
        WiFiSSIDMonitor.shared.stop()
        Task { @MainActor in
            for id in Array(instances.keys) {
                await deactivate(id)
            }
        }
    }

    // MARK: - Registration

    func register<P: CustomNotchPlugin>(type: P.Type) {
        let meta = type.metadata
        metadataByID[meta.id] = meta
        factories[meta.id] = { type.init() }
    }

    private func registerBuiltIns() {
        register(type: HelloSamplePlugin.self)
        register(type: WizLampPlugin.self)
        register(type: AudioOutputPlugin.self)
    }

    private func rebuildAvailable() {
        available = metadataByID.values
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    // MARK: - Enable state

    func isEnabled(_ id: PluginID) -> Bool {
        let map = Defaults[.pluginEnabledState]
        if let stored = map[id.rawValue] {
            return stored
        }
        return metadataByID[id]?.defaultEnabled ?? false
    }

    func setEnabled(_ id: PluginID, enabled: Bool) {
        var map = Defaults[.pluginEnabledState]
        map[id.rawValue] = enabled
        Defaults[.pluginEnabledState] = map

        Task { @MainActor in
            if enabled {
                if metadataByID[id]?.capabilities.contains(.wifiSSID) == true {
                    WiFiSSIDMonitor.shared.start()
                }
                await activate(id)
            } else {
                await deactivate(id)
            }
        }
    }

    // MARK: - Lifecycle

    func activate(_ id: PluginID) async {
        guard instances[id] == nil, let factory = factories[id] else { return }

        let plugin = factory()
        let host = PluginHostImpl(pluginID: id, manager: self)
        hosts[id] = host
        instances[id] = plugin

        await plugin.activate(host: host)
        PluginRegistry.shared.setStatus(.active, for: id)
        host.logger.info("Activated")
    }

    func deactivate(_ id: PluginID) async {
        if let plugin = instances[id] {
            await plugin.deactivate()
        }
        PluginRegistry.shared.clearSurfaces(for: id)
        PluginRegistry.shared.setStatus(.inactive, for: id)
        instances.removeValue(forKey: id)
        if let host = hosts.removeValue(forKey: id) {
            host.logger.info("Deactivated")
        }
    }

    // MARK: - Events

    func broadcast(_ event: HostEvent) {
        for host in hosts.values {
            host.deliver(event)
        }
    }

    /// SSID events only go to plugins that declared the wifiSSID capability.
    func broadcastWiFiSSIDChanged(_ ssid: String?) {
        for (id, host) in hosts {
            guard metadataByID[id]?.capabilities.contains(.wifiSSID) == true else { continue }
            host.deliver(.wifiSSIDChanged(ssid: ssid))
        }
    }

    // MARK: - Notch control

    func openNotch(to panel: PluginID?) {
        if let panel {
            CustomViewCoordinator.shared.currentView = .plugin(panel)
        }
        NotificationCenter.default.post(name: .pluginRequestOpenNotch, object: panel?.rawValue)
    }

    func closeNotch() {
        NotificationCenter.default.post(name: .pluginRequestCloseNotch, object: nil)
    }

    func metadata(for id: PluginID) -> PluginMetadata? {
        metadataByID[id]
    }

    func status(for id: PluginID) -> PluginRuntimeStatus {
        PluginRegistry.shared.statuses[id] ?? .inactive
    }
}

extension Notification.Name {
    static let pluginRequestOpenNotch = Notification.Name("pluginRequestOpenNotch")
    static let pluginRequestCloseNotch = Notification.Name("pluginRequestCloseNotch")
}
