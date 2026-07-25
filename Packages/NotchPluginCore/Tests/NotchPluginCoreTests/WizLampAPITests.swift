import XCTest
@testable import NotchPluginCore

final class WizLampAPITests: XCTestCase {
    func testConfigurationRequiresHost() {
        var config = WizLampConfiguration()
        XCTAssertFalse(config.isConfigured)
        config.host = "192.168.1.50"
        XCTAssertTrue(config.isConfigured)
    }

    func testSSIDMatchingIsCaseInsensitive() {
        let config = WizLampConfiguration(targetSSIDs: ["Home-WiFi", "Office"])
        XCTAssertTrue(config.matchesSSID("home-wifi"))
        XCTAssertTrue(config.matchesSSID("OFFICE"))
        XCTAssertFalse(config.matchesSSID("Cafe"))
        XCTAssertFalse(config.matchesSSID(nil))
    }

    func testTargetSSIDsTextParsing() {
        var config = WizLampConfiguration()
        config.targetSSIDsText = "Home, Office; Cafe\nLab"
        XCTAssertEqual(config.targetSSIDs, ["Home", "Office", "Cafe", "Lab"])
    }

    func testSSIDAutomationPowerOnWhenEnteringTarget() {
        let config = WizLampConfiguration(
            host: "1.2.3.4",
            targetSSIDs: ["Desk"],
            autoPowerOnMatchingSSID: true,
            autoPowerOffLeavingSSID: true
        )
        XCTAssertEqual(
            WizSSIDAutomation.action(config: config, previousSSID: "Elsewhere", currentSSID: "Desk"),
            .powerOn
        )
    }

    func testSSIDAutomationPowerOffWhenLeavingTarget() {
        let config = WizLampConfiguration(
            host: "1.2.3.4",
            targetSSIDs: ["Desk"],
            autoPowerOnMatchingSSID: true,
            autoPowerOffLeavingSSID: true
        )
        XCTAssertEqual(
            WizSSIDAutomation.action(config: config, previousSSID: "Desk", currentSSID: "Elsewhere"),
            .powerOff
        )
    }

    func testSSIDAutomationNoneWhenDisabled() {
        let config = WizLampConfiguration(
            host: "1.2.3.4",
            targetSSIDs: ["Desk"],
            autoPowerOnMatchingSSID: false,
            autoPowerOffLeavingSSID: false
        )
        XCTAssertEqual(
            WizSSIDAutomation.action(config: config, previousSSID: nil, currentSSID: "Desk"),
            .none
        )
    }

    func testSetPowerRequestEncoding() throws {
        let data = try JSONEncoder().encode(WizLampRequest.setPower(true))
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        XCTAssertEqual(json["method"] as? String, "setPilot")
        let params = try XCTUnwrap(json["params"] as? [String: Any])
        XCTAssertEqual(params["state"] as? Bool, true)
    }

    func testClientNotConfigured() async {
        let client = WizLampClient(
            configuration: WizLampConfiguration(host: ""),
            transport: WizClosureTransport { _, _, _ in Data() }
        )
        do {
            _ = try await client.setPower(true)
            XCTFail("Expected notConfigured")
        } catch let error as WizLampClientError {
            XCTAssertEqual(error, .notConfigured)
        } catch {
            XCTFail("Unexpected \(error)")
        }
    }

    func testClientSetPowerWithMockTransport() async throws {
        let transport = WizClosureTransport { payload, host, port in
            XCTAssertEqual(host, "10.0.0.5")
            XCTAssertEqual(port, 38899)
            let json = try JSONSerialization.jsonObject(with: payload) as? [String: Any]
            XCTAssertEqual(json?["method"] as? String, "setPilot")
            return Data(#"{"result":{"state":true,"dimming":80}}"#.utf8)
        }
        let client = WizLampClient(
            configuration: WizLampConfiguration(host: "10.0.0.5", port: 38899),
            transport: transport
        )
        let result = try await client.setPower(true)
        XCTAssertEqual(result.state, true)
        XCTAssertEqual(result.dimming, 80)
    }

    func testClientAPIError() async {
        let transport = WizClosureTransport { _, _, _ in
            Data(#"{"error":{"code":1,"message":"bulb busy"}}"#.utf8)
        }
        let client = WizLampClient(
            configuration: WizLampConfiguration(host: "10.0.0.5"),
            transport: transport
        )
        do {
            _ = try await client.fetchPilot()
            XCTFail("Expected api error")
        } catch let error as WizLampClientError {
            XCTAssertEqual(error, .api("bulb busy"))
        } catch {
            XCTFail("Unexpected \(error)")
        }
    }
}
