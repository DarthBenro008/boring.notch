import XCTest
@testable import NotchPluginCore

final class AudioOutputLogicTests: XCTestCase {
    func testSortedDevicesPutsDefaultFirstThenName() {
        let devices = [
            AudioOutputDevice(id: 1, name: "Zebra", uid: "z", isDefault: false),
            AudioOutputDevice(id: 2, name: "Alpha", uid: "a", isDefault: false),
            AudioOutputDevice(id: 3, name: "MacBook Speakers", uid: "m", isDefault: true)
        ]
        let sorted = AudioOutputLogic.sortedDevices(devices)
        XCTAssertEqual(sorted.map(\.id), [3, 2, 1])
    }

    func testMarkDefault() {
        let devices = [
            AudioOutputDevice(id: 1, name: "A", uid: "a", isDefault: true),
            AudioOutputDevice(id: 2, name: "B", uid: "b", isDefault: false)
        ]
        let updated = AudioOutputLogic.markDefault(id: 2, in: devices)
        XCTAssertFalse(updated[0].isDefault)
        XCTAssertTrue(updated[1].isDefault)
    }

    func testDefaultDeviceFallback() {
        let none = [
            AudioOutputDevice(id: 9, name: "Only", uid: "o", isDefault: false)
        ]
        XCTAssertEqual(AudioOutputLogic.defaultDevice(in: none)?.id, 9)
        XCTAssertNil(AudioOutputLogic.defaultDevice(in: []))
    }

    func testTransportTypeFourCC() {
        XCTAssertEqual(AudioOutputLogic.transportType(fourCC: 0x626C746E), .builtIn)
        XCTAssertEqual(AudioOutputLogic.transportType(fourCC: 0x626C7565), .bluetooth)
        XCTAssertEqual(AudioOutputLogic.transportType(fourCC: 0x75736220), .usb)
        XCTAssertEqual(AudioOutputLogic.transportType(fourCC: 0x61697270), .airPlay)
        XCTAssertEqual(AudioOutputLogic.transportType(fourCC: 0x12345678), .unknown)
    }

    func testSystemImages() {
        XCTAssertEqual(
            AudioOutputDevice(id: 1, name: "BT", uid: "b", transportType: .bluetooth).systemImage,
            "airpodspro"
        )
        XCTAssertEqual(
            AudioOutputDevice(id: 1, name: "AP", uid: "a", transportType: .airPlay).systemImage,
            "airplayaudio"
        )
    }
}
