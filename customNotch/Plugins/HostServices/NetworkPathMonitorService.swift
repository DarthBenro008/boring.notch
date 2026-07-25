//
//  NetworkPathMonitorService.swift
//  customNotch
//

import Foundation
import Network

/// Observes network path changes and broadcasts to plugins.
@MainActor
final class NetworkPathMonitorService {
    static let shared = NetworkPathMonitorService()

    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "customnotch.networkpath")
    private(set) var isSatisfied: Bool = true
    private var started = false

    private init() {}

    func start() {
        guard !started else { return }
        started = true
        monitor.pathUpdateHandler = { [weak self] path in
            let satisfied = path.status == .satisfied
            Task { @MainActor in
                guard let self else { return }
                guard self.isSatisfied != satisfied else { return }
                self.isSatisfied = satisfied
                PluginManager.shared.broadcast(.networkPathChanged(isSatisfied: satisfied))
            }
        }
        monitor.start(queue: queue)
    }

    func stop() {
        guard started else { return }
        monitor.cancel()
        started = false
    }
}
