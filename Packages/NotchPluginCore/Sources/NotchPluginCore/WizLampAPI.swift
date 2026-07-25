import Foundation

/// Configuration for a local WiZ bulb (LAN JSON API on UDP/HTTP port 38899).
public struct WizLampConfiguration: Codable, Equatable, Sendable {
    public var host: String
    public var port: Int
    public var targetSSIDs: [String]
    public var autoPowerOnMatchingSSID: Bool
    public var autoPowerOffLeavingSSID: Bool
    public var lastKnownOn: Bool?
    public var lastKnownDimming: Int?

    public init(
        host: String = "",
        port: Int = 38899,
        targetSSIDs: [String] = [],
        autoPowerOnMatchingSSID: Bool = true,
        autoPowerOffLeavingSSID: Bool = false,
        lastKnownOn: Bool? = nil,
        lastKnownDimming: Int? = nil
    ) {
        self.host = host
        self.port = port
        self.targetSSIDs = targetSSIDs
        self.autoPowerOnMatchingSSID = autoPowerOnMatchingSSID
        self.autoPowerOffLeavingSSID = autoPowerOffLeavingSSID
        self.lastKnownOn = lastKnownOn
        self.lastKnownDimming = lastKnownDimming
    }

    public var isConfigured: Bool {
        !host.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    public func matchesSSID(_ ssid: String?) -> Bool {
        guard let ssid, !ssid.isEmpty else { return false }
        let needle = ssid.lowercased()
        return targetSSIDs.contains {
            $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == needle
        }
    }

    /// Comma/newline separated SSID list for settings UI.
    public var targetSSIDsText: String {
        get { targetSSIDs.joined(separator: ", ") }
        set {
            targetSSIDs = newValue
                .split { $0 == "," || $0 == "\n" || $0 == ";" }
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
        }
    }
}

public enum WizLampMethod: String, Sendable {
    case getPilot
    case setPilot
}

public struct WizLampRequest: Encodable, Sendable {
    public let method: String
    public let params: [String: WizJSONValue]

    public init(method: WizLampMethod, params: [String: WizJSONValue] = [:]) {
        self.method = method.rawValue
        self.params = params
    }

    public static func setPower(_ on: Bool) -> WizLampRequest {
        WizLampRequest(method: .setPilot, params: ["state": .bool(on)])
    }

    public static func setBrightness(_ dimming: Int) -> WizLampRequest {
        let clamped = min(100, max(10, dimming))
        return WizLampRequest(method: .setPilot, params: ["dimming": .int(clamped)])
    }

    public static func getPilot() -> WizLampRequest {
        WizLampRequest(method: .getPilot)
    }
}

public enum WizJSONValue: Encodable, Sendable, Equatable {
    case bool(Bool)
    case int(Int)
    case string(String)

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .bool(let v): try container.encode(v)
        case .int(let v): try container.encode(v)
        case .string(let v): try container.encode(v)
        }
    }
}

public struct WizPilotResult: Decodable, Equatable, Sendable {
    public var state: Bool?
    public var dimming: Int?
    public var mac: String?
    public var rssi: Int?

    public init(state: Bool? = nil, dimming: Int? = nil, mac: String? = nil, rssi: Int? = nil) {
        self.state = state
        self.dimming = dimming
        self.mac = mac
        self.rssi = rssi
    }
}

public struct WizLampResponse: Decodable, Equatable, Sendable {
    public var result: WizPilotResult?
    public var error: WizLampErrorBody?

    public init(result: WizPilotResult? = nil, error: WizLampErrorBody? = nil) {
        self.result = result
        self.error = error
    }
}

public struct WizLampErrorBody: Decodable, Equatable, Sendable {
    public var code: Int?
    public var message: String?
}

public enum WizLampClientError: Error, Equatable, LocalizedError {
    case notConfigured
    case invalidURL
    case httpStatus(Int)
    case decodingFailed
    case transport(String)
    case api(String)
    case timeout

    public var errorDescription: String? {
        switch self {
        case .notConfigured: return "Bulb host is not configured"
        case .invalidURL: return "Invalid bulb address"
        case .httpStatus(let code): return "HTTP \(code)"
        case .decodingFailed: return "Failed to decode WiZ response"
        case .transport(let msg): return msg
        case .api(let msg): return msg
        case .timeout: return "Timed out waiting for bulb"
        }
    }
}

/// Byte-level transport (UDP for real bulbs; HTTP/mock for tests).
public protocol WizTransport: Sendable {
    func exchange(payload: Data, host: String, port: UInt16) async throws -> Data
}

/// HTTP POST transport (useful for mocks / proxies).
public struct WizHTTPTransport: WizTransport {
    public init() {}

    public func exchange(payload: Data, host: String, port: UInt16) async throws -> Data {
        var components = URLComponents()
        components.scheme = "http"
        components.host = host
        components.port = Int(port)
        guard let url = components.url else { throw WizLampClientError.invalidURL }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = payload
        request.timeoutInterval = 5
        let (data, response) = try await URLSession.shared.data(for: request)
        if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
            throw WizLampClientError.httpStatus(http.statusCode)
        }
        return data
    }
}

/// Injected mock / test transport.
public struct WizClosureTransport: WizTransport {
    private let handler: @Sendable (Data, String, UInt16) async throws -> Data

    public init(_ handler: @escaping @Sendable (Data, String, UInt16) async throws -> Data) {
        self.handler = handler
    }

    public func exchange(payload: Data, host: String, port: UInt16) async throws -> Data {
        try await handler(payload, host, port)
    }
}

public struct WizLampClient: Sendable {
    public var configuration: WizLampConfiguration
    private let transport: any WizTransport
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    public init(
        configuration: WizLampConfiguration,
        transport: any WizTransport
    ) {
        self.configuration = configuration
        self.transport = transport
    }

    public func send(_ body: WizLampRequest) async throws -> WizLampResponse {
        let host = configuration.host.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !host.isEmpty else { throw WizLampClientError.notConfigured }
        let payload = try encoder.encode(body)
        let data: Data
        do {
            data = try await transport.exchange(
                payload: payload,
                host: host,
                port: UInt16(configuration.port)
            )
        } catch let error as WizLampClientError {
            throw error
        } catch {
            throw WizLampClientError.transport(error.localizedDescription)
        }

        do {
            let decoded = try decoder.decode(WizLampResponse.self, from: data)
            if let message = decoded.error?.message {
                throw WizLampClientError.api(message)
            }
            return decoded
        } catch let error as WizLampClientError {
            throw error
        } catch {
            throw WizLampClientError.decodingFailed
        }
    }

    public func setPower(_ on: Bool) async throws -> WizPilotResult {
        let response = try await send(.setPower(on))
        return response.result ?? WizPilotResult(state: on)
    }

    public func setBrightness(_ dimming: Int) async throws -> WizPilotResult {
        let response = try await send(.setBrightness(dimming))
        return response.result ?? WizPilotResult(dimming: dimming)
    }

    public func fetchPilot() async throws -> WizPilotResult {
        let response = try await send(.getPilot())
        guard let result = response.result else {
            throw WizLampClientError.decodingFailed
        }
        return result
    }
}

public enum WizSSIDAutomation {
    public enum Action: Equatable, Sendable {
        case powerOn
        case powerOff
        case none
    }

    public static func action(
        config: WizLampConfiguration,
        previousSSID: String?,
        currentSSID: String?
    ) -> Action {
        let wasMatching = config.matchesSSID(previousSSID)
        let isMatching = config.matchesSSID(currentSSID)

        if !wasMatching && isMatching && config.autoPowerOnMatchingSSID {
            return .powerOn
        }
        if wasMatching && !isMatching && config.autoPowerOffLeavingSSID {
            return .powerOff
        }
        return .none
    }
}
