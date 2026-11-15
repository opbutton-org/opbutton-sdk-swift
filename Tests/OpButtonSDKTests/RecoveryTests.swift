import XCTest
@testable import OpButtonSDK

private final class RecoveryScenario: @unchecked Sendable {
    private let lock = NSLock()
    private var polls = 0
    private var samples = 0
    private var level = 1
    private var onClose: (() -> Void)?
    var widgetId = 0
    var acceptedAttributes: (() -> Void)?

    func setLevel(_ value: Int) { lock.lock(); level = value; lock.unlock() }
    func getLevel() -> Int { lock.lock(); defer { lock.unlock() }; return level }
    func recordSample() { lock.lock(); samples += 1; lock.unlock() }
    func sampleCount() -> Int { lock.lock(); defer { lock.unlock() }; return samples }
    func whenClosed(_ callback: @escaping () -> Void) { lock.lock(); onClose = callback; lock.unlock() }

    func respond(_ request: URLRequest) -> (Int, [String: Any]) {
        if request.url!.path == "/api/client/session/close" {
            lock.lock()
            let callback = onClose
            lock.unlock()
            callback?()
            return (200, [:])
        }
        if request.url!.path == "/api/client/connect" {
            return (200, ["request_id": "request", "status": "approved", "session_token": "test-session"])
        }
        guard request.url!.path == "/api/client/session/actions/poll" else { return (200, [:]) }
        lock.lock()
        polls += 1
        let poll = polls
        lock.unlock()
        if poll == 1 {
            // Ensure sampling has started before the simulated server failure.
            Thread.sleep(forTimeInterval: 0.1)
            return (503, ["detail": "temporary failure"])
        }
        if poll == 2 {
            return (200, ["actions": [[
                "id": "command", "session_id": "session", "widget_id": widgetId,
                "action_type": "click", "status": "delivered", "payload": [:]
            ]]])
        }
        if let body = Self.body(request),
           let json = try? JSONSerialization.jsonObject(with: body) as? [String: Any],
           let attributes = json["session_attributes"] as? [String: Any], attributes["level"] as? Int == 2 {
            acceptedAttributes?()
        }
        return (200, ["actions": []])
    }

    private static func body(_ request: URLRequest) -> Data? {
        if let body = request.httpBody { return body }
        guard let stream = request.httpBodyStream else { return nil }
        stream.open()
        defer { stream.close() }
        var result = Data()
        var buffer = [UInt8](repeating: 0, count: 4096)
        while true {
            let count = stream.read(&buffer, maxLength: buffer.count)
            if count <= 0 { break }
            result.append(buffer, count: count)
        }
        return result
    }
}

private final class RecoveryURLProtocol: URLProtocol, @unchecked Sendable {
    static var scenario: RecoveryScenario?
    override class func canInit(with request: URLRequest) -> Bool { request.url?.host == "opbutton.invalid" }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
    override func startLoading() {
        guard let scenario = Self.scenario else { client?.urlProtocol(self, didFailWithError: URLError(.cancelled)); return }
        let (status, body) = scenario.respond(request)
        let response = HTTPURLResponse(url: request.url!, statusCode: status, httpVersion: nil,
                                       headerFields: ["Content-Type": "application/json"])!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: try! JSONSerialization.data(withJSONObject: body))
        client?.urlProtocolDidFinishLoading(self)
    }
    override func stopLoading() {}
}

final class RecoveryTests: XCTestCase {
    private final class Collector: OpButtonMetricCollector {
        let scenario: RecoveryScenario
        init(_ scenario: RecoveryScenario) { self.scenario = scenario }
        func collect(_ out: inout [OpButtonMetricEntry]) { scenario.recordSample() }
    }
    private final class Listener: OpButtonSessionListener {
        let scenario: RecoveryScenario
        init(_ scenario: RecoveryScenario) { self.scenario = scenario }
        func onOpButtonSessionStarted(_ token: String) { scenario.setLevel(2) }
    }

    override func tearDown() {
        OpButton.shutdown()
        RecoveryURLProtocol.scenario = nil
        super.tearDown()
    }

    func testRecoveryDeliversCommandsRetriesAttributesAndKeepsSampling() {
        let scenario = RecoveryScenario()
        let command = expectation(description: "command returned by recovery poll")
        let attributes = expectation(description: "failed attribute delta retried")
        attributes.assertForOverFulfill = false
        scenario.acceptedAttributes = { attributes.fulfill() }
        let listener = Listener(scenario)
        let config = OpButtonConfig.Builder("https://opbutton.invalid", "test")
            .setAutoConnect(false).setDeviceId("test-device").setDeviceName("Test").setActionPollIntervalMs(100)
            .setSessionListener(listener)
            .setSessionAttributes(OpButtonSessionAttributes().putProvider("level") { scenario.getLevel() })
            .setMetricConfig(OpButtonMetricConfig().setSampleIntervalMs(100).addCollector(Collector(scenario)))
            .build()
        let session = URLSessionConfiguration.ephemeral
        session.protocolClasses = [RecoveryURLProtocol.self]
        RecoveryURLProtocol.scenario = scenario
        OpButton.initialize(config, httpClient: OpButtonHttpClient(baseUrl: config.baseUrl, apiToken: config.apiToken,
                                                                   configuration: session))
        let button = OpButton.getUI().addTab("Controls").vertical().addButton("Run")
        scenario.widgetId = button.internalId
        button.onClick { (_: OpButtonAction) in
            XCTAssertTrue(Thread.isMainThread)
            command.fulfill()
        }
        OpButton.connect()
        wait(for: [command, attributes], timeout: 8)
        let before = scenario.sampleCount()
        let sampled = expectation(description: "sampling continues after recovery")
        DispatchQueue.global().asyncAfter(deadline: .now() + 0.4) { sampled.fulfill() }
        wait(for: [sampled], timeout: 2)
        XCTAssertGreaterThan(scenario.sampleCount(), before)

        let closed = expectation(description: "terminal request completes before transport invalidation")
        scenario.whenClosed { closed.fulfill() }
        OpButton.shutdown()
        wait(for: [closed], timeout: 3)
        XCTAssertFalse(OpButton.isInitialized)
    }
}
