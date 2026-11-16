import XCTest
@testable import OpButtonSDK

private final class RunPeer: @unchecked Sendable {
    var requests: [URLRequest] = []
    var runs: [String] = []
    func respond(_ request: URLRequest) throws -> Data {
        requests.append(request)
        if let stream = request.httpBodyStream {
            stream.open()
            defer { stream.close() }
            var data = Data()
            var buffer = [UInt8](repeating: 0, count: 4096)
            while true {
                let count = stream.read(&buffer, maxLength: buffer.count)
                if count <= 0 { break }
                data.append(buffer, count: count)
            }
            let body = try JSONSerialization.jsonObject(with: data) as! [String: Any]
            runs.append(body["run_id"] as! String)
        } else if let data = request.httpBody {
            let body = try JSONSerialization.jsonObject(with: data) as! [String: Any]
            runs.append(body["run_id"] as! String)
        }
        if requests.count == 1 { throw URLError(.networkConnectionLost) }
        return Data("{\"request_id\":\"request\",\"status\":\"pending\"}".utf8)
    }
}

private final class RunProtocol: URLProtocol, @unchecked Sendable {
    static var peer: RunPeer?
    override class func canInit(with request: URLRequest) -> Bool { request.url?.host == "run.invalid" }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
    override func startLoading() {
        do {
            let data = try Self.peer!.respond(request)
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil,
                                           headerFields: ["Content-Type": "application/json"])!
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch { client?.urlProtocol(self, didFailWithError: error) }
    }
    override func stopLoading() {}
}

final class SessionRunTests: XCTestCase {
    func testRetriesAndApprovalPollKeepIdentityButNextSdkGetsAnother() throws {
        let peer = RunPeer()
        RunProtocol.peer = peer
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [RunProtocol.self]
        let first = OpButtonHttpClient(baseUrl: "https://run.invalid", apiToken: "test", configuration: configuration)
        let next = OpButtonHttpClient(baseUrl: "https://run.invalid", apiToken: "test", configuration: configuration)
        defer { first.shutdown(); next.shutdown(); RunProtocol.peer = nil }
        XCTAssertThrowsError(try first.connect(deviceId: "phone", deviceName: "Phone", sessionAttributes: [:]))
        _ = try first.connect(deviceId: "phone", deviceName: "Phone", sessionAttributes: [:])
        _ = try first.pollStatus(requestId: "request")
        _ = try next.connect(deviceId: "phone", deviceName: "Phone", sessionAttributes: [:])
        XCTAssertEqual(peer.runs.count, 3)
        XCTAssertEqual(peer.runs[0], peer.runs[1])
        let query = URLComponents(url: peer.requests[2].url!, resolvingAgainstBaseURL: false)!.queryItems!
        XCTAssertEqual(query.first { $0.name == "run_id" }?.value, peer.runs[0])
        XCTAssertNotEqual(peer.runs[0], peer.runs[2])
        for run in peer.runs { XCTAssertNotNil(UUID(uuidString: run)) }
        for request in peer.requests { XCTAssertEqual(request.value(forHTTPHeaderField: "X-Api-Token"), "test") }
    }
}
