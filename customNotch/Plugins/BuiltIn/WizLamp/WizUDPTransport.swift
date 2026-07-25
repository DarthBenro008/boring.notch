//
//  WizUDPTransport.swift
//  customNotch
//

import Foundation
import Network
import NotchPluginCore
import CustomNotchPluginSDK

/// WiZ bulbs speak JSON over UDP port 38899.
struct WizUDPTransport: WizTransport {
    var timeout: TimeInterval = 3

    func exchange(payload: Data, host: String, port: UInt16) async throws -> Data {
        try await withCheckedThrowingContinuation { continuation in
            let queue = DispatchQueue(label: "customnotch.wiz.udp")
            let connection = NWConnection(
                host: NWEndpoint.Host(host),
                port: NWEndpoint.Port(rawValue: port) ?? 38899,
                using: .udp
            )

            var settled = false
            let finish: (Result<Data, Error>) -> Void = { result in
                queue.async {
                    guard !settled else { return }
                    settled = true
                    connection.cancel()
                    continuation.resume(with: result)
                }
            }

            connection.stateUpdateHandler = { state in
                switch state {
                case .ready:
                    connection.send(
                        content: payload,
                        completion: .contentProcessed { error in
                            if let error {
                                finish(.failure(WizLampClientError.transport(error.localizedDescription)))
                            }
                        }
                    )
                    connection.receiveMessage { data, _, _, error in
                        if let error {
                            finish(.failure(WizLampClientError.transport(error.localizedDescription)))
                            return
                        }
                        guard let data, !data.isEmpty else {
                            finish(.failure(WizLampClientError.decodingFailed))
                            return
                        }
                        finish(.success(data))
                    }
                case .failed(let error):
                    finish(.failure(WizLampClientError.transport(error.localizedDescription)))
                case .cancelled:
                    break
                default:
                    break
                }
            }

            connection.start(queue: queue)

            queue.asyncAfter(deadline: .now() + timeout) {
                finish(.failure(WizLampClientError.timeout))
            }
        }
    }
}
