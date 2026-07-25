import XCTest
@testable import NotchPluginCore

final class MockAudioOutputProvider: AudioOutputProviding {
    var devices: [AudioOutputDevice]
    var defaultOutputDeviceID: UInt32?
    private(set) var lastSetID: UInt32?

    init(devices: [AudioOutputDevice]) {
        self.devices = devices
        self.defaultOutputDeviceID = devices.first(where: \.isDefault)?.id
    }

    func listOutputDevices() throws -> [AudioOutputDevice] {
        AudioOutputLogic.sortedDevices(devices)
    }

    func setDefaultOutputDevice(id: UInt32) throws {
        lastSetID = id
        defaultOutputDeviceID = id
        devices = AudioOutputLogic.markDefault(id: id, in: devices)
    }
}

final class MockAudioProviderTests: XCTestCase {
    func testSelectDefaultUpdatesList() throws {
        let provider = MockAudioOutputProvider(devices: [
            AudioOutputDevice(id: 1, name: "Speakers", uid: "s", isDefault: true),
            AudioOutputDevice(id: 2, name: "AirPods", uid: "a", transportType: .bluetooth, isDefault: false)
        ])
        try provider.setDefaultOutputDevice(id: 2)
        XCTAssertEqual(provider.lastSetID, 2)
        let devices = try provider.listOutputDevices()
        XCTAssertEqual(devices.first?.id, 2)
        XCTAssertTrue(devices.first?.isDefault == true)
        XCTAssertEqual(provider.defaultOutputDeviceID, 2)
    }
}
