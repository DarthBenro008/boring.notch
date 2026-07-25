//
//  PluginsSettingsView.swift
//  customNotch
//

import SwiftUI

struct PluginsSettingsView: View {
    @ObservedObject private var manager = PluginManager.shared
    @ObservedObject private var registry = PluginRegistry.shared
    @State private var selected: PluginID?

    var body: some View {
        HSplitView {
            List(selection: $selected) {
                if manager.available.isEmpty {
                    Text("No plugins registered")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(manager.available) { meta in
                        PluginListRow(
                            metadata: meta,
                            enabled: manager.isEnabled(meta.id),
                            status: manager.status(for: meta.id)
                        )
                        .tag(meta.id)
                    }
                }
            }
            .frame(minWidth: 220, idealWidth: 260)

            Group {
                if let id = selected, let meta = manager.metadata(for: id) {
                    PluginDetailView(metadata: meta)
                } else {
                    ContentUnavailableView(
                        "Plugins",
                        systemImage: "puzzlepiece.extension",
                        description: Text("Select a plugin to configure it. Plugins extend the notch with custom panels, live activities, and actions.")
                    )
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .navigationTitle("Plugins")
        .onAppear {
            if selected == nil {
                selected = manager.available.first?.id
            }
        }
    }
}

private struct PluginListRow: View {
    let metadata: PluginMetadata
    let enabled: Bool
    let status: PluginRuntimeStatus

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: metadata.iconSystemName)
                .frame(width: 24)
            VStack(alignment: .leading, spacing: 2) {
                Text(metadata.name)
                Text(statusLabel)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Circle()
                .fill(statusColor)
                .frame(width: 8, height: 8)
        }
        .padding(.vertical, 2)
    }

    private var statusLabel: String {
        if !enabled { return "Disabled" }
        switch status {
        case .active: return "Running"
        case .inactive: return "Inactive"
        case .failed(let msg): return "Failed: \(msg)"
        }
    }

    private var statusColor: Color {
        if !enabled { return .gray }
        switch status {
        case .active: return .green
        case .inactive: return .orange
        case .failed: return .red
        }
    }
}

private struct PluginDetailView: View {
    let metadata: PluginMetadata
    @ObservedObject private var manager = PluginManager.shared
    @ObservedObject private var registry = PluginRegistry.shared

    private var enabled: Bool {
        manager.isEnabled(metadata.id)
    }

    var body: some View {
        Form {
            Section {
                LabeledContent("Name", value: metadata.name)
                LabeledContent("Version", value: metadata.version)
                LabeledContent("Author", value: metadata.author)
                Text(metadata.summary)
                    .foregroundStyle(.secondary)
                Toggle("Enabled", isOn: Binding(
                    get: { manager.isEnabled(metadata.id) },
                    set: { manager.setEnabled(metadata.id, enabled: $0) }
                ))
            } header: {
                Label(metadata.name, systemImage: metadata.iconSystemName)
            }

            if !metadata.capabilities.isEmpty {
                Section("Capabilities") {
                    ForEach(metadata.capabilities.displayNames, id: \.self) { name in
                        Label(name, systemImage: "checkmark.shield")
                    }
                }
            }

            if enabled, let settings = registry.settings[metadata.id] {
                Section("Plugin settings") {
                    settings.makeView()
                }
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}
