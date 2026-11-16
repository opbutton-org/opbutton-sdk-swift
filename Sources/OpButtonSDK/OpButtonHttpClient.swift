import Foundation

final class OpButtonHttpClient: OpButtonPollTransport {
    private let baseUrl: String
    private let apiToken: String
    private let runId = UUID().uuidString
    private let session: URLSession
    private let sessionDelegate: BoundedSessionDelegate
    private let sessionLock = NSLock()
    private var closed = false
    private var deviceSecret = UUID().uuidString + UUID().uuidString
    private static let maxResponseBytes = 2 * 1024 * 1024

    private final class ResponseBox: @unchecked Sendable {
        var data = Data()
        var http: HTTPURLResponse?
        var error: Error?
        let semaphore = DispatchSemaphore(value: 0)
    }

    private final class BoundedSessionDelegate: NSObject, URLSessionDataDelegate,
                                                @unchecked Sendable {
        private let maxResponseBytes: Int
        private let lock = NSLock()
        private var responses: [Int: ResponseBox] = [:]

        init(maxResponseBytes: Int) {
            self.maxResponseBytes = maxResponseBytes
        }

        func register(_ task: URLSessionTask, response: ResponseBox) {
            lock.lock()
            responses[task.taskIdentifier] = response
            lock.unlock()
        }

        func urlSession(_ session: URLSession, dataTask: URLSessionDataTask,
                        didReceive response: URLResponse,
                        completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
            lock.lock()
            let box = responses[dataTask.taskIdentifier]
            box?.http = response as? HTTPURLResponse
            let tooLarge = response.expectedContentLength > Int64(maxResponseBytes)
            if tooLarge {
                box?.error = OpButtonError("Server response exceeds 2 MiB")
            }
            lock.unlock()
            completionHandler(tooLarge ? .cancel : .allow)
        }

        func urlSession(_ session: URLSession, dataTask: URLSessionDataTask,
                        didReceive data: Data) {
            lock.lock()
            guard let box = responses[dataTask.taskIdentifier] else {
                lock.unlock()
                dataTask.cancel()
                return
            }
            if box.data.count > maxResponseBytes - data.count {
                box.error = OpButtonError("Server response exceeds 2 MiB")
                lock.unlock()
                dataTask.cancel()
                return
            }
            box.data.append(data)
            lock.unlock()
        }

        func urlSession(_ session: URLSession, task: URLSessionTask,
                        didCompleteWithError error: Error?) {
            lock.lock()
            guard let box = responses.removeValue(forKey: task.taskIdentifier) else {
                lock.unlock()
                return
            }
            if box.error == nil {
                box.error = error
            }
            lock.unlock()
            box.semaphore.signal()
        }

        func urlSession(_ session: URLSession, task: URLSessionTask,
                        willPerformHTTPRedirection response: HTTPURLResponse,
                        newRequest request: URLRequest,
                        completionHandler: @escaping (URLRequest?) -> Void) {
            completionHandler(nil)
        }
    }

    init(baseUrl: String, apiToken: String, configuration: URLSessionConfiguration = .default) {
        self.baseUrl = baseUrl
        self.apiToken = apiToken

        let config = configuration
        config.timeoutIntervalForRequest = 15
        config.timeoutIntervalForResource = 30
        let delegate = BoundedSessionDelegate(maxResponseBytes: Self.maxResponseBytes)
        self.sessionDelegate = delegate
        self.session = URLSession(configuration: config, delegate: delegate, delegateQueue: nil)
    }

    func shutdown() {
        sessionLock.lock()
        defer { sessionLock.unlock() }
        guard !closed else { return }
        closed = true
        session.invalidateAndCancel()
    }

    func setDeviceSecret(_ value: String) throws {
        guard Self.isSafeDeviceSecret(value) else {
            throw OpButtonError(
                "Device credential must contain 32 to 256 printable ASCII characters")
        }
        sessionLock.lock()
        deviceSecret = value
        sessionLock.unlock()
    }

    private static func isSafeDeviceSecret(_ value: String) -> Bool {
        (32...256).contains(value.count) && value.unicodeScalars.allSatisfy {
            (0x21...0x7e).contains($0.value)
        }
    }

    private func currentDeviceSecret() -> String {
        sessionLock.lock()
        defer { sessionLock.unlock() }
        return deviceSecret
    }

    // MARK: - Client Endpoints

    func connect(deviceId: String, deviceName: String,
                 sessionAttributes: [String: Any]) throws -> OpButtonConnectResponse {
        let credential = currentDeviceSecret()
        var body: [String: Any] = [
            "device_id": deviceId,
            "device_name": deviceName,
            "run_id": runId,
            "device_secret": credential
        ]

        if !sessionAttributes.isEmpty {
            body["session_attributes"] = sessionAttributes
        }

        let json = try executeSync(
            path: "/api/client/connect",
            method: "POST",
            body: body,
            token: apiToken,
            tokenHeader: "X-Api-Token"
        )

        return OpButtonConnectResponse.fromJson(json)
    }

    func pollStatus(requestId: String) throws -> OpButtonConnectResponse {
        let credential = currentDeviceSecret()
        let json = try executeSync(
            path: "/api/client/poll-status/\(requestId)?run_id=\(runId)",
            method: "GET",
            body: nil,
            token: apiToken,
            tokenHeader: "X-Api-Token",
            additionalHeaders: ["X-Device-Secret": credential]
        )

        return OpButtonConnectResponse.fromJson(json)
    }

    func closeSession(sessionToken: String) throws -> Bool {
        let json = try executeSync(
            path: "/api/client/session/close",
            method: "POST",
            body: [:],
            token: sessionToken,
            tokenHeader: "X-Session-Token"
        )

        return json["ok"] as? Bool ?? false
    }

    func submitPanel(sessionToken: String, layout: [String: Any]) throws -> [String: Any] {
        let body: [String: Any] = ["layout": layout]

        return try executeSync(
            path: "/api/client/session/panel",
            method: "POST",
            body: body,
            token: sessionToken,
            tokenHeader: "X-Session-Token"
        )
    }

    func pollActions(sessionToken: String,
                     changedAttributes: [String: Any]?,
                     logs: [OpButtonLogEntry],
                     metrics: [OpButtonMetricEntry]) throws -> [String: Any] {
        var body: [String: Any] = [:]

        if let attrs = changedAttributes, !attrs.isEmpty {
            body["session_attributes"] = attrs
        }

        if !logs.isEmpty {
            body["logs"] = logs.map { $0.toJson() }
        }

        if !metrics.isEmpty {
            body["metrics"] = metrics.map { $0.toJson() }
        }

        return try executeSync(
            path: "/api/client/session/actions/poll",
            method: "POST",
            body: body.isEmpty ? nil : body,
            token: sessionToken,
            tokenHeader: "X-Session-Token"
        )
    }

    func acknowledgeAction(sessionToken: String, actionId: String,
                           ackPayload: [String: Any]?) throws {
        let body: [String: Any] = [
            "action_id": actionId,
            "ack_payload": ackPayload ?? [:]
        ]

        _ = try executeSync(
            path: "/api/client/session/actions/ack",
            method: "POST",
            body: body,
            token: sessionToken,
            tokenHeader: "X-Session-Token"
        )
    }

    func sendLogs(sessionToken: String, logs: [OpButtonLogEntry]) throws {
        guard !logs.isEmpty else { return }

        let body: [String: Any] = [
            "logs": logs.map { $0.toJson() }
        ]

        _ = try executeSync(
            path: "/api/client/session/logs",
            method: "POST",
            body: body,
            token: sessionToken,
            tokenHeader: "X-Session-Token"
        )
    }

    func sendMetrics(sessionToken: String, metrics: [OpButtonMetricEntry]) throws {
        guard !metrics.isEmpty else { return }

        let body: [String: Any] = [
            "metrics": metrics.map { $0.toJson() }
        ]

        _ = try executeSync(
            path: "/api/client/session/metrics",
            method: "POST",
            body: body,
            token: sessionToken,
            tokenHeader: "X-Session-Token"
        )
    }

    func getLivePublisherState(sessionToken: String) throws -> [String: Any] {
        return try executeSync(
            path: "/api/client/session/live/publisher",
            method: "GET",
            body: nil,
            token: sessionToken,
            tokenHeader: "X-Session-Token"
        )
    }

    // MARK: - Internal

    @discardableResult
    private func executeSync(path: String, method: String,
                             body: [String: Any]?,
                             token: String, tokenHeader: String,
                             additionalHeaders: [String: String] = [:]) throws -> [String: Any] {
        guard let url = URL(string: baseUrl + path) else {
            throw OpButtonError("Invalid URL: \(baseUrl + path)")
        }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue(token, forHTTPHeaderField: tokenHeader)
        for (name, value) in additionalHeaders {
            request.setValue(value, forHTTPHeaderField: name)
        }
        request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")

        if let body = body, method != "GET" {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        }

        let result = ResponseBox()

        // URLSession raises an Objective-C exception for task creation after invalidation.
        // Serialize acquiring a task with closing its owning session.
        sessionLock.lock()
        guard !closed else {
            sessionLock.unlock()
            throw OpButtonError("HTTP client is shut down")
        }
        let task = session.dataTask(with: request)
        sessionDelegate.register(task, response: result)
        sessionLock.unlock()
        task.resume()
        result.semaphore.wait()

        if let error = result.error {
            throw OpButtonError("Network error: \(error.localizedDescription)", cause: error)
        }

        guard let httpResponse = result.http else {
            throw OpButtonError("No HTTP response")
        }

        let bodyString = String(data: result.data, encoding: .utf8) ?? ""

        guard (200...299).contains(httpResponse.statusCode) else {
            var detail = bodyString
            if let errorJson = try? JSONSerialization.jsonObject(with: result.data) as? [String: Any],
               let d = errorJson["detail"] as? String {
                detail = d
            }
            throw OpButtonError(httpCode: httpResponse.statusCode, "HTTP \(httpResponse.statusCode): \(detail)")
        }

        if bodyString.isEmpty {
            return [:]
        }

        guard let json = try? JSONSerialization.jsonObject(with: result.data) as? [String: Any] else {
            throw OpButtonError("Failed to parse server response")
        }

        return json
    }
}
