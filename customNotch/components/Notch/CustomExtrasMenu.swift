//
//  CustomExtrasMenu.swift
//  customNotch
//
//  Created by Harsh Vardhan  Goswami  on 04/08/24.
//

import SwiftUI
import CustomNotchPluginSDK

struct CustomLargeButtons: View {
    var action: () -> Void
    var icon: Image
    var title: String
    var body: some View {
        Button (
            action:action,
            label: {
                ZStack {
                    RoundedRectangle(cornerRadius: 12.0).fill(.black).frame(width: 70, height: 70)
                    VStack(spacing: 8) {
                        icon.resizable()
                            .aspectRatio(contentMode: .fit).frame(width:20)
                        Text(title).font(.body)
                    }
                }
            }).buttonStyle(PlainButtonStyle()).shadow(color: .black.opacity(0.5), radius: 10)
    }
}

struct CustomExtrasMenu : View {
    @ObservedObject var vm: CustomViewModel
    @ObservedObject private var pluginRegistry = PluginRegistry.shared
    
    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 20)  {
                hide
                settings
                close
            }
            if !pluginRegistry.menuItems.isEmpty {
                HStack(spacing: 12) {
                    ForEach(pluginRegistry.menuItems) { item in
                        Button {
                            guard item.isEnabled() else { return }
                            item.action()
                        } label: {
                            VStack(spacing: 6) {
                                Image(systemName: item.systemImage ?? "puzzlepiece.extension")
                                    .font(.system(size: 14, weight: .semibold))
                                Text(item.title)
                                    .font(.caption2)
                                    .lineLimit(2)
                                    .multilineTextAlignment(.center)
                            }
                            .frame(width: 70, height: 70)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(.black)
                            )
                        }
                        .buttonStyle(.plain)
                        .disabled(!item.isEnabled())
                        .opacity(item.isEnabled() ? 1 : 0.4)
                        .shadow(color: .black.opacity(0.5), radius: 10)
                    }
                }
            }
        }
    }
    
    var github: some View {
        CustomLargeButtons(
            action: {
                if let url = URL(string: "https://github.com/YOUR_USERNAME/custom.notch") {
                    NSWorkspace.shared.open(url)
                }
            },
            icon: Image(.github),
            title: "Checkout"
        )
    }
    
    var settings: some View {
        Button(action: {
            DispatchQueue.main.async {
                SettingsWindowController.shared.showWindow()
            }
        }) {
            ZStack {
                RoundedRectangle(cornerRadius: 12.0).fill(.black).frame(width: 70, height: 70)
                VStack(spacing: 8) {
                    Image(systemName: "gear").resizable()
                        .aspectRatio(contentMode: .fit).frame(width:20)
                    Text("Settings").font(.body)
                }
            }
        }
        .buttonStyle(PlainButtonStyle()).shadow(color: .black.opacity(0.5), radius: 10)
    }
    
    var hide: some View {
        CustomLargeButtons(
            action: {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                    //vm.openMusic()
                }
            },
            icon: Image(systemName: "arrow.down.forward.and.arrow.up.backward"),
            title: "Hide"
        )
    }
    
    var close: some View {
        CustomLargeButtons(
            action: {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                        NSApp.terminate(nil)
                    }
                }
            },
            icon: Image(systemName: "xmark"),
            title: "Exit"
        )
    }
}


#Preview {
    CustomExtrasMenu(vm: .init())
}
