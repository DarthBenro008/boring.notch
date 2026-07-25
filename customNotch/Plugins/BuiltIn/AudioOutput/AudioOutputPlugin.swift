//
//  AudioOutputPlugin.swift
//  customNotch
//

import NotchPluginCore
import SwiftUI
import CustomNotchPluginSDK

@MainActor
final class AudioOutputPlugin: CustomNotchPlugin {
    static let metadata = PluginMetadata(
        id: PluginID("custom.notch.plugin.audio"),
        name: "Audio Output",
        version: "1.0.0",
        author: "Custom Notch",
        summary: "Pick speakers, AirPods, and other system audio outputs from the notch.",
        iconSystemName: "hifispeaker.fill",
        capabilities: [],
        defaultEnabled: true
    )

    private var host: PluginHost?
    private var subscription: PluginEventSubscription?
    private let provider: any AudioOutputProviding
    private(set) var devices: [AudioOutputDevice] = []
    private(set) var statusText: String = "Loading…"
    private var showLiveChip = false
    private var errorText: String?

    init() {
        self.provider = CoreAudioOutputProvider()
    }

    /// Test seam.
    init(provider: any AudioOutputProviding) {
        self.provider = provider
    }

    func activate(host: PluginHost) async {
        self.host = host
        showLiveChip = host.storage.bool(forKey: "showLiveChip", default: false)
        refreshDevices()
        registerSurfaces()

        subscription = host.subscribe { [weak self] event in
            guard let self else { return }
            switch event {
            case .notchDidOpen, .didLaunch:
                self.refreshDevices()
                self.reregister()
            default:
                break
            }
        }
    }

    func deactivate() async {
        subscription?.cancel()
        subscription = nil
        host = nil
    }

    private func registerSurfaces() {
        guard let host else { return }

        host.registerPanel(
            PluginPanelSpec(
                title: "Audio",
                systemImage: "hifispeaker.fill",
                sortOrder: 30
            ) { [weak self] in
                AnyView(AudioOutputPanelView(plugin: self!))
            }
        )

        host.registerLiveActivity(
            PluginLiveActivitySpec(
                priority: 35,
                isActive: { [weak self] in self?.showLiveChip == true }
            ) { [weak self] in
                let name = self?.currentDevice?.name ?? "Audio"
                let icon = self?.currentDevice?.systemImage ?? "hifispeaker.fill"
                return AnyView(AudioOutputLiveActivity(name: name, systemImage: icon))
            }
        )

        host.registerMenuItems([
            PluginMenuItem(
                id: "open",
                title: "Audio outputs",
                systemImage: "hifispeaker"
            ) { [weak self] in
                self?.host?.openNotch(to: Self.metadata.id)
            }
        ])

        host.registerSettings(
            PluginSettingsSpec { [weak self] in
                AnyView(AudioOutputSettingsView(plugin: self!))
            }
        )
    }

    private func reregister() {
        registerSurfaces()
        PluginRegistry.shared.objectWillChange.send()
    }

    func refreshDevices() {
        do {
            devices = try provider.listOutputDevices()
            errorText = nil
            if let current = currentDevice {
                statusText = current.name
            } else {
                statusText = "No devices"
            }
        } catch {
            errorText = error.localizedDescription
            statusText = "Error"
            host?.logger.error("listOutputDevices: \(error.localizedDescription)")
        }
        reregister()
    }

    var currentDevice: AudioOutputDevice? {
        AudioOutputLogic.defaultDevice(in: devices)
    }

    func selectDevice(_ device: AudioOutputDevice) {
        do {
            try provider.setDefaultOutputDevice(id: device.id)
            devices = AudioOutputLogic.markDefault(id: device.id, in: devices)
            devices = AudioOutputLogic.sortedDevices(devices)
            statusText = device.name
            errorText = nil
            host?.showSneakPeek(
                PluginSneakPeek(
                    title: device.name,
                    systemImage: device.systemImage,
                    duration: 1.5
                )
            )
            reregister()
        } catch {
            errorText = error.localizedDescription
            host?.logger.error("setDefaultOutputDevice: \(error.localizedDescription)")
        }
    }

    var liveChipEnabled: Bool {
        get { showLiveChip }
        set {
            showLiveChip = newValue
            host?.storage.set(newValue, forKey: "showLiveChip")
            reregister()
        }
    }

    var errorMessage: String? { errorText }
}

// MARK: - Views

struct AudioOutputPanelView: View {
    let plugin: AudioOutputPlugin

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "hifispeaker.fill")
                    .font(.title2)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Audio Output")
                        .font(.headline)
                    Text(plugin.statusText)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                Spacer()
                Button {
                    plugin.refreshDevices()
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .buttonStyle(.borderless)
                .help("Refresh devices")
            }

            if let error = plugin.errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
            }

            ScrollView {
                VStack(spacing: 6) {
                    ForEach(plugin.devices) { device in
                        Button {
                            plugin.selectDevice(device)
                        } label: {
                            HStack(spacing: 10) {
                                Image(systemName: device.systemImage)
                                    .frame(width: 18)
                                Text(device.name)
                                    .lineLimit(1)
                                Spacer()
                                if device.isDefault {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(.green)
                                }
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(device.isDefault ? Color.white.opacity(0.12) : Color.white.opacity(0.05))
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .onAppear { plugin.refreshDevices() }
    }
}

struct AudioOutputLiveActivity: View {
    let name: String
    let systemImage: String

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: systemImage)
                .font(.system(size: 11, weight: .semibold))
            Text(name)
                .font(.system(size: 11, weight: .medium))
                .lineLimit(1)
        }
        .foregroundStyle(.white.opacity(0.9))
        .padding(.horizontal, 8)
    }
}

struct AudioOutputSettingsView: View {
    let plugin: AudioOutputPlugin
    @State private var liveChip = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Toggle("Show current output on closed notch", isOn: $liveChip)
                .onChange(of: liveChip) { _, newValue in
                    plugin.liveChipEnabled = newValue
                }
            Text("Lists system output devices via Core Audio (built-in speakers, Bluetooth, USB, AirPlay when available).")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .onAppear {
            liveChip = plugin.liveChipEnabled
        }
    }
}
