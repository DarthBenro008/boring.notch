//
//  PluginSurfaces.swift
//  customNotch
//

import SwiftUI

public struct PluginPanelSpec {
    public var title: String
    public var systemImage: String
    public var sortOrder: Int
    public var preferredOpenHeight: CGFloat?
    public var makeView: @MainActor () -> AnyView

    public init(
        title: String,
        systemImage: String,
        sortOrder: Int = 100,
        preferredOpenHeight: CGFloat? = nil,
        makeView: @escaping @MainActor () -> AnyView
    ) {
        self.title = title
        self.systemImage = systemImage
        self.sortOrder = sortOrder
        self.preferredOpenHeight = preferredOpenHeight
        self.makeView = makeView
    }
}

public struct PluginLiveActivitySpec {
    public var priority: Int
    public var isActive: () -> Bool
    public var makeView: @MainActor () -> AnyView

    public init(
        priority: Int = 50,
        isActive: @escaping () -> Bool,
        makeView: @escaping @MainActor () -> AnyView
    ) {
        self.priority = priority
        self.isActive = isActive
        self.makeView = makeView
    }
}

public struct PluginMenuItem: Identifiable {
    public var id: String
    public var title: String
    public var systemImage: String?
    public var isEnabled: () -> Bool
    public var action: @MainActor () -> Void

    public init(
        id: String,
        title: String,
        systemImage: String? = nil,
        isEnabled: @escaping () -> Bool = { true },
        action: @escaping @MainActor () -> Void
    ) {
        self.id = id
        self.title = title
        self.systemImage = systemImage
        self.isEnabled = isEnabled
        self.action = action
    }
}

public struct PluginSettingsSpec {
    public var makeView: @MainActor () -> AnyView

    public init(makeView: @escaping @MainActor () -> AnyView) {
        self.makeView = makeView
    }
}

public struct PluginSneakPeek {
    public var title: String
    public var systemImage: String
    public var value: CGFloat?
    public var duration: TimeInterval

    public init(
        title: String,
        systemImage: String = "puzzlepiece.extension",
        value: CGFloat? = nil,
        duration: TimeInterval = 1.5
    ) {
        self.title = title
        self.systemImage = systemImage
        self.value = value
        self.duration = duration
    }
}
