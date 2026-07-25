//
//  WiFiSSIDMonitor.swift
//  customNotch
//

import CoreLocation
import CoreWLAN
import Foundation

/// Best-effort current Wi‑Fi SSID monitoring (requires Location permission on modern macOS).
@MainActor
final class WiFiSSIDMonitor: NSObject, CLLocationManagerDelegate {
    static let shared = WiFiSSIDMonitor()

    private let locationManager = CLLocationManager()
    private var timer: Timer?
    private(set) var currentSSID: String?
    private var started = false
    private var authorizationRequested = false

    private override init() {
        super.init()
        locationManager.delegate = self
    }

    var isAuthorized: Bool {
        let status = locationManager.authorizationStatus
        return status == .authorized || status == .authorizedAlways
    }

    func start() {
        guard !started else { return }
        started = true
        requestAuthorizationIfNeeded()
        poll()
        timer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.poll()
            }
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        started = false
    }

    func requestAuthorizationIfNeeded() {
        let status = locationManager.authorizationStatus
        switch status {
        case .notDetermined:
            guard !authorizationRequested else { return }
            authorizationRequested = true
            locationManager.requestWhenInUseAuthorization()
        default:
            break
        }
    }

    func refresh() {
        poll()
    }

    private func poll() {
        let ssid = fetchSSID()
        guard ssid != currentSSID else { return }
        currentSSID = ssid
        // Only broadcast SSID to plugins that declared wifiSSID; PluginManager filters.
        PluginManager.shared.broadcastWiFiSSIDChanged(ssid)
    }

    private func fetchSSID() -> String? {
        // CoreWLAN is the supported path; may return nil without location auth or when offline.
        if let interface = CWWiFiClient.shared().interface(),
           let ssid = interface.ssid(),
           !ssid.isEmpty {
            return ssid
        }
        return nil
    }

    // MARK: - CLLocationManagerDelegate

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            self.poll()
        }
    }
}
