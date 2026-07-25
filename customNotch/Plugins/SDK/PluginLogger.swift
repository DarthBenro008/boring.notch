//
//  PluginLogger.swift
//  customNotch
//

import Foundation
import OSLog

public struct PluginLogger: Sendable {
    private let logger: Logger

    public init(pluginID: PluginID) {
        self.logger = Logger(
            subsystem: Bundle.main.bundleIdentifier ?? "customnotch.customnotch",
            category: "plugin.\(pluginID.rawValue)"
        )
    }

    public func debug(_ message: String) {
        logger.debug("\(message, privacy: .public)")
    }

    public func info(_ message: String) {
        logger.info("\(message, privacy: .public)")
    }

    public func error(_ message: String) {
        logger.error("\(message, privacy: .public)")
    }
}
