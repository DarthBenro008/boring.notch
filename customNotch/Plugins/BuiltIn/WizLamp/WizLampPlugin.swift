//
//  WizLampPlugin.swift
//  customNotch
//

import NotchPluginCore
import SwiftUI
import CustomNotchPluginSDK

@MainActor
final class WizLampPlugin: CustomNotchPlugin {
    static let metadata = PluginMetadata(
        id: PluginID("custom.notch.plugin.wiz"),
        name: "WiZ Desk Lamp",
        version: "1.0.0",
        author: "Custom Notch",
        summary: "Control a Philips WiZ lamp on your LAN and automate power from Wi‑Fi SSID.",
        iconSystemName: "lightbulb.fill",
        capabilities: [.network, .wifiSSID],
        defaultEnabled: false
    )

    private var host: PluginHost?
    private var subscription: PluginEventSubscription?
    private var config = WizLampConfiguration()
    private var previousSSID: String?
    private var isOn: Bool = false
    private var dimming: Double = 80
    private var statusText: String = "Not configured"
    private var isBusy = false
    private var showLiveChip = false

    private var client: WizLampClient {
        WizLampClient(configuration: config, transport: WizUDPTransport())
    }

    func activate(host: PluginHost) async {
        self.host = host
        loadConfig(from: host.storage)
        previousSSID = WiFiSSIDMonitor.shared.currentSSID
        isOn = config.lastKnownOn ?? false
        dimming = Double(config.lastKnownDimming ?? 80)
        refreshStatusLabel()
        registerSurfaces()
        WiFiSSIDMonitor.shared.requestAuthorizationIfNeeded()

        subscription = host.subscribe { [weak self] event in
            guard let self else { return }
            switch event {
            case .wifiSSIDChanged(let ssid):
                self.handleSSIDChange(ssid)
            case .didLaunch:
                Task { await self.refreshFromBulb() }
            default:
                break
            }
        }

        if config.isConfigured {
            await refreshFromBulb()
        }
    }

    func deactivate() async {
        subscription?.cancel()
        subscription = nil
        host = nil
    }

    // MARK: - Surfaces

    private func registerSurfaces() {
        guard let host else { return }

        host.registerPanel(
            PluginPanelSpec(
                title: "Lamp",
                systemImage: "lightbulb.fill",
                sortOrder: 40
            ) { [weak self] in
                AnyView(WizLampPanelView(plugin: self!))
            }
        )

        host.registerLiveActivity(
            PluginLiveActivitySpec(
                priority: 55,
                isActive: { [weak self] in self?.showLiveChip == true }
            ) { [weak self] in
                AnyView(WizLampLiveActivity(isOn: self?.isOn ?? false, dimming: Int(self?.dimming ?? 0)))
            }
        )

        host.registerMenuItems([
            PluginMenuItem(
                id: "toggle",
                title: isOn ? "Lamp off" : "Lamp on",
                systemImage: isOn ? "lightbulb.fill" : "lightbulb"
            ) { [weak self] in
                Task { await self?.togglePower() }
            },
            PluginMenuItem(
                id: "open",
                title: "Lamp panel",
                systemImage: "slider.horizontal.3"
            ) { [weak self] in
                self?.host?.openNotch(to: Self.metadata.id)
            }
        ])

        host.registerSettings(
            PluginSettingsSpec { [weak self] in
                AnyView(WizLampSettingsView(plugin: self!))
            }
        )
    }

    private func reregisterDynamicSurfaces() {
        registerSurfaces()
        PluginRegistry.shared.objectWillChange.send()
    }

    // MARK: - Config persistence

    private func loadConfig(from storage: PluginStorage) {
        config.host = storage.string(forKey: "host") ?? ""
        config.port = Int(storage.double(forKey: "port", default: 38899))
        if let ssids = storage.string(forKey: "targetSSIDs") {
            config.targetSSIDsText = ssids
        }
        config.autoPowerOnMatchingSSID = storage.bool(forKey: "autoOn", default: true)
        config.autoPowerOffLeavingSSID = storage.bool(forKey: "autoOff", default: false)
        if storage.string(forKey: "lastKnownOn") != nil {
            config.lastKnownOn = storage.bool(forKey: "lastKnownOn", default: false)
        }
        let dim = Int(storage.double(forKey: "lastKnownDimming", default: 80))
        config.lastKnownDimming = dim
        showLiveChip = storage.bool(forKey: "showLiveChip", default: true)
    }

    func saveConfig() {
        guard let storage = host?.storage else { return }
        storage.set(config.host, forKey: "host")
        storage.set(Double(config.port), forKey: "port")
        storage.set(config.targetSSIDsText, forKey: "targetSSIDs")
        storage.set(config.autoPowerOnMatchingSSID, forKey: "autoOn")
        storage.set(config.autoPowerOffLeavingSSID, forKey: "autoOff")
        storage.set(showLiveChip, forKey: "showLiveChip")
        if let on = config.lastKnownOn {
            storage.set(on, forKey: "lastKnownOn")
        }
        if let dim = config.lastKnownDimming {
            storage.set(Double(dim), forKey: "lastKnownDimming")
        }
        refreshStatusLabel()
        reregisterDynamicSurfaces()
    }

    // MARK: - Actions

    func togglePower() async {
        await setPower(!isOn)
    }

    func setPower(_ on: Bool) async {
        guard config.isConfigured else {
            statusText = "Configure bulb IP in settings"
            return
        }
        isBusy = true
        defer { isBusy = false }
        do {
            let result = try await client.setPower(on)
            isOn = result.state ?? on
            config.lastKnownOn = isOn
            if let d = result.dimming { dimming = Double(d); config.lastKnownDimming = d }
            saveConfig()
            statusText = isOn ? "On" : "Off"
            host?.showSneakPeek(
                PluginSneakPeek(
                    title: isOn ? "Desk lamp on" : "Desk lamp off",
                    systemImage: isOn ? "lightbulb.fill" : "lightbulb",
                    duration: 1.6
                )
            )
            reregisterDynamicSurfaces()
        } catch {
            statusText = error.localizedDescription
            host?.logger.error("setPower failed: \(error.localizedDescription)")
        }
    }

    func applyBrightness() async {
        guard config.isConfigured else { return }
        isBusy = true
        defer { isBusy = false }
        do {
            let value = Int(dimming.rounded())
            let result = try await client.setBrightness(value)
            if let d = result.dimming { dimming = Double(d) }
            config.lastKnownDimming = Int(dimming)
            // Setting dimming often implies on
            isOn = true
            config.lastKnownOn = true
            saveConfig()
            statusText = "Brightness \(Int(dimming))%"
            reregisterDynamicSurfaces()
        } catch {
            statusText = error.localizedDescription
        }
    }

    func refreshFromBulb() async {
        guard config.isConfigured else {
            statusText = "Not configured"
            return
        }
        isBusy = true
        defer { isBusy = false }
        do {
            let result = try await client.fetchPilot()
            if let state = result.state { isOn = state; config.lastKnownOn = state }
            if let d = result.dimming { dimming = Double(d); config.lastKnownDimming = d }
            saveConfig()
            statusText = isOn ? "On · \(Int(dimming))%" : "Off"
            reregisterDynamicSurfaces()
        } catch {
            statusText = error.localizedDescription
        }
    }

    private func handleSSIDChange(_ ssid: String?) {
        let action = WizSSIDAutomation.action(
            config: config,
            previousSSID: previousSSID,
            currentSSID: ssid
        )
        previousSSID = ssid
        switch action {
        case .powerOn:
            Task { await setPower(true) }
        case .powerOff:
            Task { await setPower(false) }
        case .none:
            break
        }
    }

    private func refreshStatusLabel() {
        if !config.isConfigured {
            statusText = "Not configured"
        } else if statusText == "Not configured" {
            statusText = isOn ? "On" : "Off"
        }
    }

    // Accessors for views
    var configuration: WizLampConfiguration {
        get { config }
        set { config = newValue }
    }
    var powerOn: Bool { isOn }
    var brightness: Double {
        get { dimming }
        set { dimming = newValue }
    }
    var status: String { statusText }
    var busy: Bool { isBusy }
    var liveChip: Bool {
        get { showLiveChip }
        set {
            showLiveChip = newValue
            saveConfig()
        }
    }
}

// MARK: - Views

struct WizLampPanelView: View {
    let plugin: WizLampPlugin

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: plugin.powerOn ? "lightbulb.fill" : "lightbulb")
                    .font(.title2)
                    .foregroundStyle(plugin.powerOn ? .yellow : .secondary)
                VStack(alignment: .leading, spacing: 2) {
                    Text("WiZ Desk Lamp")
                        .font(.headline)
                    Text(plugin.status)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Toggle("", isOn: Binding(
                    get: { plugin.powerOn },
                    set: { newValue in Task { await plugin.setPower(newValue) } }
                ))
                .toggleStyle(.switch)
                .labelsHidden()
                .disabled(plugin.busy || !plugin.configuration.isConfigured)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Brightness")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                HStack {
                    Slider(
                        value: Binding(
                            get: { plugin.brightness },
                            set: { plugin.brightness = $0 }
                        ),
                        in: 10...100,
                        step: 1
                    ) { editing in
                        if !editing {
                            Task { await plugin.applyBrightness() }
                        }
                    }
                    .disabled(plugin.busy || !plugin.configuration.isConfigured)
                    Text("\(Int(plugin.brightness))%")
                        .font(.caption.monospacedDigit())
                        .frame(width: 40, alignment: .trailing)
                }
            }

            HStack {
                Button("Refresh") { Task { await plugin.refreshFromBulb() } }
                    .controlSize(.small)
                Spacer()
                Text(plugin.configuration.host.isEmpty ? "Set IP in Settings → Plugins" : plugin.configuration.host)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

struct WizLampLiveActivity: View {
    let isOn: Bool
    let dimming: Int

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: isOn ? "lightbulb.fill" : "lightbulb")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(isOn ? .yellow : .white.opacity(0.7))
            Text(isOn ? "\(dimming)%" : "Off")
                .font(.system(size: 11, weight: .medium))
        }
        .foregroundStyle(.white.opacity(0.9))
        .padding(.horizontal, 8)
    }
}

struct WizLampSettingsView: View {
    let plugin: WizLampPlugin
    @State private var host: String = ""
    @State private var port: String = "38899"
    @State private var ssids: String = ""
    @State private var autoOn = true
    @State private var autoOff = false
    @State private var liveChip = true

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            TextField("Bulb IP address", text: $host)
                .textFieldStyle(.roundedBorder)
            TextField("Port", text: $port)
                .textFieldStyle(.roundedBorder)
            TextField("Target Wi‑Fi SSIDs (comma-separated)", text: $ssids)
                .textFieldStyle(.roundedBorder)
            Toggle("Turn on when joining target Wi‑Fi", isOn: $autoOn)
            Toggle("Turn off when leaving target Wi‑Fi", isOn: $autoOff)
            Toggle("Show closed-notch chip", isOn: $liveChip)
            Text("Uses local UDP control (port 38899). The Mac must be on the same network as the bulb. SSID automation needs Location permission.")
                .font(.caption)
                .foregroundStyle(.secondary)
            Button("Save") { persist() }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
        }
        .onAppear {
            host = plugin.configuration.host
            port = String(plugin.configuration.port)
            ssids = plugin.configuration.targetSSIDsText
            autoOn = plugin.configuration.autoPowerOnMatchingSSID
            autoOff = plugin.configuration.autoPowerOffLeavingSSID
            liveChip = plugin.liveChip
        }
    }

    private func persist() {
        var config = plugin.configuration
        config.host = host.trimmingCharacters(in: .whitespacesAndNewlines)
        config.port = Int(port) ?? 38899
        config.targetSSIDsText = ssids
        config.autoPowerOnMatchingSSID = autoOn
        config.autoPowerOffLeavingSSID = autoOff
        plugin.configuration = config
        plugin.liveChip = liveChip
        plugin.saveConfig()
        WiFiSSIDMonitor.shared.requestAuthorizationIfNeeded()
    }
}
