//
//  PluginPanelHostView.swift
//  customNotch
//

import SwiftUI

struct PluginPanelHostView: View {
    let pluginID: PluginID
    @ObservedObject private var registry = PluginRegistry.shared

    var body: some View {
        Group {
            if let view = registry.panelView(for: pluginID) {
                view
            } else {
                VStack(spacing: 8) {
                    Image(systemName: "puzzlepiece.extension")
                        .font(.title)
                        .foregroundStyle(.secondary)
                    Text("Plugin unavailable")
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }
}
