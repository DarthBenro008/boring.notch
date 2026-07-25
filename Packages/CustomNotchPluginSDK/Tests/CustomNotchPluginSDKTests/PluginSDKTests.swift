import XCTest
@testable import CustomNotchPluginSDK

final class PluginSDKTests: XCTestCase {
    func testSDKVersionCompatible() {
        XCTAssertTrue(PluginSDKVersion.isCompatible(pluginMajor: PluginSDKVersion.major))
        XCTAssertFalse(PluginSDKVersion.isCompatible(pluginMajor: PluginSDKVersion.major + 1))
        XCTAssertFalse(PluginSDKVersion.isCompatible(pluginMajor: 0))
    }

    func testPluginID() {
        let id = PluginID("com.example.plugin")
        XCTAssertEqual(id.rawValue, "com.example.plugin")
        XCTAssertEqual(id.description, "com.example.plugin")
    }

    func testCapabilityManifestParsing() {
        let set = PluginCapabilitySet.parseManifestList("network, wifiSSID; localNetwork")
        XCTAssertTrue(set.contains(.network))
        XCTAssertTrue(set.contains(.wifiSSID))
        XCTAssertTrue(set.contains(.localNetwork))
        XCTAssertFalse(set.contains(.notifications))
        XCTAssertEqual(set.manifestString.split(separator: ",").count, 3)
    }

    func testEmptyCapabilities() {
        XCTAssertTrue(PluginCapabilitySet.parseManifestList(nil).isEmpty)
        XCTAssertTrue(PluginCapabilitySet.parseManifestList("").isEmpty)
        XCTAssertTrue(PluginCapabilitySet.parseManifestList("unknown-token").isEmpty)
    }

    func testMetadataIdentifiable() {
        let meta = PluginMetadata(
            id: PluginID("custom.notch.plugin.hello"),
            name: "Hello",
            version: "1.0.0",
            author: "Test",
            summary: "s",
            iconSystemName: "star"
        )
        XCTAssertEqual(meta.id.rawValue, "custom.notch.plugin.hello")
    }

    func testBundleKeysStable() {
        XCTAssertEqual(PluginBundleKeys.bundleExtension, "cnplugin")
        XCTAssertEqual(PluginBundleKeys.sdkVersion, "CNPluginSDKVersion")
        XCTAssertEqual(PluginSDKVersion.infoPlistMajorKey, PluginBundleKeys.sdkVersion)
    }
}
