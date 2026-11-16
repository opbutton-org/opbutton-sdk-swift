import XCTest
@testable import OpButtonSDK

final class SecurityContractsTests: XCTestCase {
    func testSecureAndExplicitLocalDevelopmentBaseUrls() {
        let secure = OpButtonConfig.Builder("https://example.com", "token").build()
        XCTAssertEqual(secure.baseUrl, "https://example.com")

        let local = OpButtonConfig.Builder("http://127.0.0.1:8000", "token")
            .setAllowInsecureLocalhost(true)
            .build()
        XCTAssertEqual(local.baseUrl, "http://127.0.0.1:8000")

        let ipv6 = OpButtonConfig.Builder("http://[::1]:8000", "token")
            .setAllowInsecureLocalhost(true)
            .build()
        XCTAssertEqual(ipv6.baseUrl, "http://[::1]:8000")
    }

    func testHttpClientRejectsCredentialsOutsideProtocolBounds() {
        let client = OpButtonHttpClient(baseUrl: "https://example.com", apiToken: "token")
        defer { client.shutdown() }

        XCTAssertThrowsError(try client.setDeviceSecret("short"))
        XCTAssertThrowsError(try client.setDeviceSecret(String(repeating: "x", count: 257)))
        XCTAssertThrowsError(try client.setDeviceSecret(String(repeating: "x", count: 32) + "\n"))
        XCTAssertNoThrow(try client.setDeviceSecret(String(repeating: "x", count: 32)))
    }
}
