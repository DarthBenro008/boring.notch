//
//  TabSelectionView.swift
//  customNotch
//
//  Created by Hugo Persson on 2024-08-25.
//

import Defaults
import SwiftUI
import CustomNotchPluginSDK

struct TabModel: Identifiable {
    let id: String
    let label: String
    let icon: String
    let view: NotchViews
}

struct TabSelectionView: View {
    @ObservedObject var coordinator = CustomViewCoordinator.shared
    @ObservedObject private var pluginRegistry = PluginRegistry.shared
    @Default(.customShelf) private var shelfEnabled
    @Namespace var animation

    private var tabs: [TabModel] {
        var result: [TabModel] = [
            TabModel(id: "home", label: "Home", icon: "house.fill", view: .home)
        ]
        if shelfEnabled {
            result.append(TabModel(id: "shelf", label: "Shelf", icon: "tray.fill", view: .shelf))
        }
        for (pluginID, panel) in pluginRegistry.orderedPanels {
            result.append(
                TabModel(
                    id: pluginID.rawValue,
                    label: panel.title,
                    icon: panel.systemImage,
                    view: .plugin(pluginID)
                )
            )
        }
        return result
    }

    var body: some View {
        HStack(spacing: 0) {
            ForEach(tabs) { tab in
                TabButton(label: tab.label, icon: tab.icon, selected: coordinator.currentView == tab.view) {
                    withAnimation(.smooth) {
                        coordinator.currentView = tab.view
                    }
                }
                .frame(height: 26)
                .foregroundStyle(tab.view == coordinator.currentView ? .white : .gray)
                .background {
                    if tab.view == coordinator.currentView {
                        Capsule()
                            .fill(Color(nsColor: .secondarySystemFill))
                            .matchedGeometryEffect(id: "capsule", in: animation)
                    } else {
                        Capsule()
                            .fill(Color.clear)
                            .matchedGeometryEffect(id: "capsule", in: animation)
                            .hidden()
                    }
                }
            }
        }
        .clipShape(Capsule())
    }
}

#Preview {
    CustomHeader().environmentObject(CustomViewModel())
}
