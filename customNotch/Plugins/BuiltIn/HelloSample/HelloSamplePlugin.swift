//
//  HelloSamplePlugin.swift
//  customNotch
//
//  Reference first-party plugin that exercises all v1 surfaces.
//

import SwiftUI
import CustomNotchPluginSDK

@MainActor
final class HelloSamplePlugin: CustomNotchPlugin {
    static let metadata = PluginMetadata(
        id: PluginID("custom.notch.plugin.hello"),
        name: "Hello Sample",
        version: "1.0.0",
        author: "Custom Notch",
        summary: "Demo plugin that shows a panel, menu action, live activity, and settings.",
        iconSystemName: "hand.wave.fill",
        capabilities: [],
        defaultEnabled: true
    )

    private var host: PluginHost?
    private var subscription: PluginEventSubscription?
    private var showLiveChip = false
    private var greeting: String = "Hello from plugin"

    func activate(host: PluginHost) async {
        self.host = host
        greeting = host.storage.string(forKey: "greeting") ?? "Hello from plugin"
        showLiveChip = host.storage.bool(forKey: "showLiveChip", default: false)

        host.registerPanel(
            PluginPanelSpec(
                title: "Hello",
                systemImage: "hand.wave.fill",
                sortOrder: 50
            ) {
                AnyView(HelloSamplePanelView(plugin: self))
            }
        )

        host.registerLiveActivity(
            PluginLiveActivitySpec(
                priority: 40,
                isActive: { [weak self] in self?.showLiveChip == true }
            ) {
                AnyView(HelloSampleLiveActivity(text: self.greeting))
            }
        )

        host.registerMenuItems([
            PluginMenuItem(
                id: "wave",
                title: "Wave hello",
                systemImage: "hand.wave"
            ) { [weak self] in
                self?.wave()
            },
            PluginMenuItem(
                id: "toggle-chip",
                title: "Toggle live chip",
                systemImage: "rectangle.dashed"
            ) { [weak self] in
                self?.toggleLiveChip()
            }
        ])

        host.registerSettings(
            PluginSettingsSpec {
                AnyView(HelloSampleSettingsView(plugin: self))
            }
        )

        subscription = host.subscribe { [weak self] event in
            guard let self else { return }
            switch event {
            case .didLaunch:
                host.logger.info("Host launched")
            case .notchDidOpen:
                host.logger.debug("Notch opened")
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

    func wave() {
        host?.showSneakPeek(
            PluginSneakPeek(
                title: greeting,
                systemImage: "hand.wave.fill",
                duration: 2
            )
        )
    }

    func toggleLiveChip() {
        showLiveChip.toggle()
        host?.storage.set(showLiveChip, forKey: "showLiveChip")
        if let host {
            host.registerLiveActivity(
                PluginLiveActivitySpec(
                    priority: 40,
                    isActive: { [weak self] in self?.showLiveChip == true }
                ) {
                    AnyView(HelloSampleLiveActivity(text: self.greeting))
                }
            )
        }
        PluginRegistry.shared.objectWillChange.send()
    }

    func updateGreeting(_ value: String) {
        greeting = value
        host?.storage.set(value, forKey: "greeting")
        if showLiveChip, let host {
            host.registerLiveActivity(
                PluginLiveActivitySpec(
                    priority: 40,
                    isActive: { [weak self] in self?.showLiveChip == true }
                ) {
                    AnyView(HelloSampleLiveActivity(text: self.greeting))
                }
            )
        }
        PluginRegistry.shared.objectWillChange.send()
    }

    var currentGreeting: String { greeting }
    var liveChipEnabled: Bool { showLiveChip }
}

// MARK: - Views

struct HelloSamplePanelView: View {
    let plugin: HelloSamplePlugin

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: "hand.wave.fill")
                    .font(.title2)
                    .foregroundStyle(.yellow)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Hello Sample")
                        .font(.headline)
                    Text(plugin.currentGreeting)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }

            Text("This panel is provided by a first-party plugin. Use it as a template when adding new notch features.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 8) {
                Button("Wave") { plugin.wave() }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)

                Button(plugin.liveChipEnabled ? "Hide chip" : "Show chip") {
                    plugin.toggleLiveChip()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

struct HelloSampleLiveActivity: View {
    let text: String

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "hand.wave.fill")
                .font(.system(size: 11, weight: .semibold))
            Text(text)
                .font(.system(size: 11, weight: .medium))
                .lineLimit(1)
        }
        .foregroundStyle(.white.opacity(0.9))
        .padding(.horizontal, 8)
    }
}

struct HelloSampleSettingsView: View {
    let plugin: HelloSamplePlugin
    @State private var greeting: String = ""
    @State private var showChip: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            TextField("Greeting", text: $greeting)
                .textFieldStyle(.roundedBorder)
                .onChange(of: greeting) { _, newValue in
                    plugin.updateGreeting(newValue)
                }
            Toggle("Show closed-notch chip", isOn: $showChip)
                .onChange(of: showChip) { _, newValue in
                    if newValue != plugin.liveChipEnabled {
                        plugin.toggleLiveChip()
                    }
                }
            Text("Demo settings stored in the plugin’s isolated preferences.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .onAppear {
            greeting = plugin.currentGreeting
            showChip = plugin.liveChipEnabled
        }
    }
}
