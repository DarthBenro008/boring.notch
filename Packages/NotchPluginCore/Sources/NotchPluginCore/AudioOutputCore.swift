import Foundation

public struct AudioOutputDevice: Identifiable, Equatable, Sendable, Hashable {
    public var id: UInt32
    public var name: String
    public var uid: String
    public var transportType: AudioTransportType
    public var isDefault: Bool

    public init(
        id: UInt32,
        name: String,
        uid: String,
        transportType: AudioTransportType = .unknown,
        isDefault: Bool = false
    ) {
        self.id = id
        self.name = name
        self.uid = uid
        self.transportType = transportType
        self.isDefault = isDefault
    }

    public var systemImage: String {
        switch transportType {
        case .bluetooth: return "airpodspro"
        case .builtIn: return "speaker.wave.2.fill"
        case .hdmi, .displayPort: return "tv"
        case .usb: return "cable.connector"
        case .airPlay: return "airplayaudio"
        case .aggregate: return "hifispeaker.fill"
        case .unknown: return "hifispeaker"
        }
    }
}

public enum AudioTransportType: String, Sendable, Codable, CaseIterable {
    case builtIn
    case bluetooth
    case usb
    case hdmi
    case displayPort
    case airPlay
    case aggregate
    case unknown
}

public protocol AudioOutputProviding: AnyObject {
    func listOutputDevices() throws -> [AudioOutputDevice]
    func setDefaultOutputDevice(id: UInt32) throws
    var defaultOutputDeviceID: UInt32? { get }
}

/// Pure helpers around device lists (testable without Core Audio).
public enum AudioOutputLogic {
    public static func sortedDevices(_ devices: [AudioOutputDevice]) -> [AudioOutputDevice] {
        devices.sorted { lhs, rhs in
            if lhs.isDefault != rhs.isDefault { return lhs.isDefault && !rhs.isDefault }
            return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
        }
    }

    public static func markDefault(
        id: UInt32,
        in devices: [AudioOutputDevice]
    ) -> [AudioOutputDevice] {
        devices.map { device in
            var copy = device
            copy.isDefault = device.id == id
            return copy
        }
    }

    public static func defaultDevice(in devices: [AudioOutputDevice]) -> AudioOutputDevice? {
        devices.first(where: \.isDefault) ?? devices.first
    }

    /// Map Core Audio transport type four-character codes.
    public static func transportType(fourCC: UInt32) -> AudioTransportType {
        switch fourCC {
        case 0x626C746E: return .builtIn      // 'bltn'
        case 0x626C7565: return .bluetooth    // 'blue'
        case 0x626C6563: return .bluetooth    // 'blec'
        case 0x75736220: return .usb          // 'usb '
        case 0x68646D69: return .hdmi         // 'hdmi'
        case 0x64706F74: return .displayPort  // 'dpot'
        case 0x61697270: return .airPlay      // 'airp'
        case 0x67726F75: return .aggregate    // 'grou'
        default: return .unknown
        }
    }
}
