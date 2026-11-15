import Foundation
#if canImport(UIKit)
import UIKit
#endif

/// Coordinates one initialized SDK instance behind the public facade.
final class OpButtonRuntime {
    private let config: OpButtonConfig
    private let httpClient: OpButtonHttpClient
    let telemetry: OpButtonTelemetry
    private let hostState: OpButtonHostState
    private lazy var delivery = OpButtonPollDelivery(
        transport: httpClient, state: hostState, telemetry: telemetry,
        isCurrent: { [weak self] in self?.isCurrentSession($0) ?? false },
        onPanelError: { [weak self] in self?.notifyError($0) })
    private let liveManager: OpButtonLiveManager
    private lazy var actions: OpButtonActionRouter = {
        let commands = OpButtonLiveCommands(live: liveManager,
            background: { [weak self] work in self?.workQueue?.async { work() } },
            isCurrent: { [weak self] in self?.isCurrentSession($0) ?? false },
            acknowledge: { [weak self] in self?.acknowledgeForSession($0, actionId: $1, payload: $2) })
        return OpButtonActionRouter(commands: commands.commands(),
            widgets: { [weak self] action in _ = self?.ui.dispatchAction(action) },
            listeners: { [weak self] in
                guard let self = self else { return [] }
                self.listenerLock.lock()
                defer { self.listenerLock.unlock() }
                return self.actionListeners
            })
    }()

    private var sessionToken: String?
    private var requestId: String?
    private var status: OpButtonSessionStatus = .disconnected
    private var running = false
    private var terminated = false
    private var actionPollInFlight = false
    private var currentActionPollIntervalMs: Int64

    private var actionListeners: [OpButtonActionListener] = []
    private var sessionListeners: [OpButtonSessionListener] = []

    let ui = OpButtonUI()
    let metrics = OpButtonMetrics()

    private let lock = NSLock()
    private let listenerLock = NSLock()

    private var workQueue: DispatchQueue?
    private var actionPollTimer: DispatchSourceTimer?
    private var metricSampleTimer: DispatchSourceTimer?

    // MARK: - Init

    init(config: OpButtonConfig, httpClient: OpButtonHttpClient?) {
        self.config = config
        let client = httpClient ?? OpButtonHttpClient(baseUrl: config.baseUrl, apiToken: config.apiToken)
        self.httpClient = client
        self.telemetry = OpButtonTelemetry(logConfig: config.logConfig, httpClient: client, metrics: metrics)
        self.hostState = OpButtonHostState(attributes: config.sessionAttributes, ui: ui)
        self.currentActionPollIntervalMs = config.actionPollIntervalMs
        self.liveManager = OpButtonLiveManager(httpClient: client)

        self.liveManager.onLiveModeChanged = { [weak self] enabled, intervalMs in
            self?.handleLiveModeChanged(enabled: enabled, intervalMs: intervalMs)
        }

        OpButtonLog.setLevel(config.logConfig.logLevel)
        OpButtonLog.setLoggerListener(config.loggerListener)

        let mc = config.metricConfig
        if mc.enabled {
            metrics.setSampleIntervalMs(mc.sampleIntervalMs)
            metrics.setBufferSize(mc.bufferSize)
            metrics.setBatchSize(mc.batchSize)
        }
        if let sl = config.sessionListener {
            sessionListeners.append(sl)
        }
        if let al = config.actionListener {
            actionListeners.append(al)
        }

        if mc.enabled {
            metrics.addCollector(OpButtonDefaultMetricCollector())
            for collector in mc.collectors {
                metrics.addCollector(collector)
            }
        }

    }

    func logConfiguration() {
        if config.metricConfig.enabled {
            OpButtonLog.i("Built-in metrics enabled (sample interval: %lldms)", config.metricConfig.sampleIntervalMs)
        }
    }

    var isLoggingEnabled: Bool { config.logConfig.enabled }
    func currentStatus() -> OpButtonSessionStatus {
        lock.lock()
        defer { lock.unlock() }
        return status
    }
    func addActionListener(_ listener: OpButtonActionListener) {
        listenerLock.lock()
        actionListeners.append(listener)
        listenerLock.unlock()
    }
    func removeActionListener(_ listener: OpButtonActionListener) {
        listenerLock.lock()
        actionListeners.removeAll { $0 === listener }
        listenerLock.unlock()
    }
    func addSessionListener(_ listener: OpButtonSessionListener) {
        listenerLock.lock()
        sessionListeners.append(listener)
        listenerLock.unlock()
    }
    func removeSessionListener(_ listener: OpButtonSessionListener) {
        listenerLock.lock()
        sessionListeners.removeAll { $0 === listener }
        listenerLock.unlock()
    }

    func startConnection() {
        lock.lock()
        guard !running, !terminated else {
            lock.unlock()
            OpButtonLog.w("Already connecting/connected")
            return
        }
        running = true
        lock.unlock()

        let queue = DispatchQueue(label: "org.opbutton.sdk", qos: .utility, attributes: .concurrent)
        workQueue = queue
        queue.async { [weak self] in
            self?.connectAndWaitApproval()
        }
    }

    func stopConnection() {
        endConnection(closingTransport: false)
    }

    private func endConnection(closingTransport: Bool) {
        lock.lock()
        guard running || closingTransport else {
            lock.unlock()
            return
        }
        let wasRunning = running
        running = false
        terminated = terminated || closingTransport
        let token = sessionToken
        sessionToken = nil
        let queue = workQueue
        lock.unlock()

        liveManager.onSessionClosed()
        cancelScheduledTasks()

        // The finalizer owns this runtime until all previously queued requests finish.
        // Clear the outbox and invalidate the transport only after terminal delivery.
        let finish = { [self] in
            if let token = token {
                do {
                    try telemetry.flushLogs(sessionToken: token)
                    try telemetry.flushMetrics(sessionToken: token)
                    _ = try httpClient.closeSession(sessionToken: token)
                } catch {}
            }
            if closingTransport {
                httpClient.shutdown()
                telemetry.clear()
                metrics.clear()
            }
            lock.lock()
            let ended = wasRunning && !running
            if ended { status = token == nil ? .disconnected : .closed }
            lock.unlock()
            if ended, token != nil { notifySessionClosed() }
        }
        if let queue = queue { queue.async(flags: .barrier) { finish() } }
        else { finish() }
    }

    func doShutdown() {
        OpButtonLog.i("Shutting down OpButton SDK")
        endConnection(closingTransport: true)
        liveManager.shutdown()

        listenerLock.lock()
        actionListeners.removeAll()
        sessionListeners.removeAll()
        listenerLock.unlock()

    }

    private func connectAndWaitApproval() {
        var retryCount = 0
        var retryDelayMs: Int64 = 2000
        let maxRetryDelayMs: Int64 = 30000

        while isRunning {
            do {
                try doConnectAndWaitApproval()
                return
            } catch let error as OpButtonError {
                if error.isUnauthorized {
                    OpButtonLog.e("Authentication failed", error)
                    setStatus(.authFailed)
                    lock.lock()
                    running = false
                    lock.unlock()
                    notifyAuthFailed()
                    return
                }

                if !error.isNetworkError {
                    OpButtonLog.e("Server error, stopping connection: %@", error.message)
                    setStatus(.error)
                    lock.lock()
                    running = false
                    lock.unlock()
                    notifyError(error)
                    return
                }

                retryCount += 1
                OpButtonLog.w("Connection attempt %d failed (network): %@, retrying in %lldms",
                           retryCount, error.message, retryDelayMs)
                setStatus(.connecting)

                Thread.sleep(forTimeInterval: TimeInterval(retryDelayMs) / 1000.0)
                retryDelayMs = min(retryDelayMs * 2, maxRetryDelayMs)
            } catch {
                retryCount += 1
                OpButtonLog.w("Connection attempt %d failed: %@", retryCount, error.localizedDescription)
                setStatus(.connecting)

                Thread.sleep(forTimeInterval: TimeInterval(retryDelayMs) / 1000.0)
                retryDelayMs = min(retryDelayMs * 2, maxRetryDelayMs)
            }
        }
    }

    private func doConnectAndWaitApproval() throws {
        setStatus(.connecting)
        notifyConnecting()

        var deviceId = config.deviceId ?? ""
        var deviceName = config.deviceName ?? ""

        #if canImport(UIKit) && !os(watchOS)
        if deviceId.isEmpty {
            deviceId = UIDevice.current.identifierForVendor?.uuidString ?? UIDevice.current.model
        }
        if deviceName.isEmpty {
            deviceName = "\(UIDevice.current.model) (iOS \(UIDevice.current.systemVersion))"
        }
        #else
        if deviceId.isEmpty {
            deviceId = Host.current().localizedName ?? "macOS"
        }
        if deviceName.isEmpty {
            let info = ProcessInfo.processInfo
            deviceName = "\(Host.current().localizedName ?? "Mac") (macOS \(info.operatingSystemVersionString))"
        }
        #endif

        let attributes = hostState.resolveAllSessionAttributes()
        let resp = try httpClient.connect(deviceId: deviceId, deviceName: deviceName,
                                          sessionAttributes: attributes)
        hostState.acknowledgeAll(attributes)

        lock.lock()
        requestId = resp.requestId
        lock.unlock()

        OpButtonLog.i("Connect request sent, request_id=%@, status=%@", resp.requestId, resp.status)

        if resp.isApproved, let token = resp.sessionToken {
            onApproved(token)
            return
        }

        if resp.isRejected {
            onRejected()
            return
        }

        setStatus(.waitingApproval)
        notifyWaitingApproval(resp.requestId)

        while isRunning {
            Thread.sleep(forTimeInterval: TimeInterval(config.pollIntervalMs) / 1000.0)

            let pollResp = try httpClient.pollStatus(requestId: resp.requestId)

            if pollResp.isApproved, let token = pollResp.sessionToken {
                onApproved(token)
                return
            }

            if pollResp.isRejected {
                onRejected()
                return
            }
        }
    }

    private func onApproved(_ token: String) {
        lock.lock()
        sessionToken = token
        lock.unlock()

        setStatus(.active)
        OpButtonLog.i("Session approved and active")
        notifySessionStarted(token)

        if ui.hasTabs, let snapshot = OpButtonMainThread.sync({ ui.snapshot() }) {
            do {
                _ = try httpClient.submitPanel(sessionToken: token, layout: snapshot.layout)
                ui.markSent(snapshot.revision)
                OpButtonLog.d("Initial UI submitted (revision=%d)", ui.getRevision())
            } catch {
                OpButtonLog.e("Failed to submit initial UI", error)
                notifyError(OpButtonError("Failed to submit initial UI", cause: error))
            }
        }

        scheduleActionPolling(sessionToken: token, intervalMs: config.actionPollIntervalMs)

        if config.metricConfig.enabled {
            let sampleMs = metrics.sampleIntervalMs
            let timer = DispatchSource.makeTimerSource(queue: workQueue)
            timer.schedule(deadline: .now() + .milliseconds(Int(sampleMs)),
                          repeating: .milliseconds(Int(sampleMs)))
            timer.setEventHandler { [weak self] in
                self?.metrics.sample()
            }
            timer.resume()

            lock.lock()
            metricSampleTimer = timer
            lock.unlock()
        }
    }

    private func onRejected() {
        OpButtonLog.w("Connection request rejected")
        setStatus(.rejected)
        lock.lock()
        running = false
        lock.unlock()
        notifyRejected()
    }

    private func doPollActions(_ token: String) {
        lock.lock()
        guard running, sessionToken == token, !actionPollInFlight else { lock.unlock(); return }
        actionPollInFlight = true
        lock.unlock()
        defer {
            lock.lock()
            actionPollInFlight = false
            lock.unlock()
        }
        do {
            let response = try delivery.exchange(token)
            processPollResponse(token, response)
        } catch let error as OpButtonError {
            guard isCurrentSession(token) else { return }
            if error.isNetworkError {
                OpButtonLog.w("Network error during action poll, will retry")
            } else {
                OpButtonLog.w("Action poll failed with server error, attempting reconnect")
                attemptReconnect(token)
            }
        } catch {
            OpButtonLog.w("Action poll failed, will retry")
        }
    }

    private func isCurrentSession(_ token: String) -> Bool {
        lock.lock()
        defer { lock.unlock() }
        return running && sessionToken == token
    }

    private func processPollResponse(_ token: String, _ response: [String: Any]) {
        guard isCurrentSession(token), let actions = response["actions"] as? [[String: Any]] else { return }
        for action in actions { dispatchAction(OpButtonAction.fromJson(action), token: token) }
    }

    private func dispatchAction(_ action: OpButtonAction, token: String) {
        let operation = { [weak self] in
            guard let self = self, self.isCurrentSession(token) else { return }
            self.actions.dispatch(action, token: token)
        }
        if Thread.isMainThread { operation() }
        else { DispatchQueue.main.async(execute: operation) }
    }

    private func scheduleActionPolling(sessionToken: String, intervalMs: Int64) {
        lock.lock()
        guard running else {
            lock.unlock()
            return
        }

        actionPollTimer?.cancel()
        actionPollTimer = nil

        currentActionPollIntervalMs = intervalMs

        let timer = DispatchSource.makeTimerSource(queue: workQueue)
        timer.schedule(deadline: .now(), repeating: .milliseconds(Int(intervalMs)))
        timer.setEventHandler { [weak self] in
            self?.doPollActions(sessionToken)
        }
        timer.resume()
        actionPollTimer = timer
        lock.unlock()
    }

    private func handleLiveModeChanged(enabled: Bool, intervalMs: Int64) {
        lock.lock()
        let token = sessionToken
        lock.unlock()

        guard let token = token else { return }

        if enabled && intervalMs > 0 {
            scheduleActionPolling(sessionToken: token, intervalMs: intervalMs)
        } else {
            scheduleActionPolling(sessionToken: token, intervalMs: config.actionPollIntervalMs)
        }
    }

    // MARK: - Log Buffer

    // MARK: - Attributes

    // MARK: - Session management

    private func attemptReconnect(_ token: String) {
        cancelActionPolling()
        setStatus(.connecting)

        var retryDelay: Int64 = 2000
        let maxDelay: Int64 = 30000

        while isCurrentSession(token) {
            Thread.sleep(forTimeInterval: TimeInterval(retryDelay) / 1000.0)

            guard isCurrentSession(token) else { return }

            do {
                let response = try httpClient.pollActions(
                    sessionToken: token,
                    changedAttributes: nil,
                    logs: [],
                    metrics: []
                )

                guard isCurrentSession(token) else { return }
                processPollResponse(token, response)
                OpButtonLog.i("Reconnect successful, session still active")
                setStatus(.active)
                scheduleActionPolling(sessionToken: token, intervalMs: currentActionPollIntervalMs)
                return

            } catch let error as OpButtonError {
                guard isCurrentSession(token) else { return }
                if error.isNetworkError {
                    OpButtonLog.w("Reconnect: no network, retrying in %lldms", retryDelay)
                    retryDelay = min(retryDelay * 2, maxDelay)
                    continue
                }

                OpButtonLog.w("Session lost (server error), starting fresh connection")
                resetAndRestart()
                return

            } catch {
                OpButtonLog.w("Reconnect: unknown error, retrying in %lldms", retryDelay)
                retryDelay = min(retryDelay * 2, maxDelay)
            }
        }
    }

    private func resetAndRestart() {
        cancelScheduledTasks()
        lock.lock()
        running = false
        sessionToken = nil
        lock.unlock()

        liveManager.onSessionClosed()
        setStatus(.disconnected)
        notifySessionClosed()

        startConnection()
    }

    private func setStatus(_ newStatus: OpButtonSessionStatus) {
        lock.lock()
        status = newStatus
        lock.unlock()
    }

    private var isRunning: Bool {
        lock.lock()
        defer { lock.unlock() }
        return running
    }

    private func cancelActionPolling() {
        lock.lock()
        actionPollTimer?.cancel()
        actionPollTimer = nil
        lock.unlock()
    }

    private func cancelScheduledTasks() {
        lock.lock()
        actionPollTimer?.cancel()
        actionPollTimer = nil
        metricSampleTimer?.cancel()
        metricSampleTimer = nil
        lock.unlock()
    }

    // MARK: - Listener Notifications

    private func notifySessionListeners(_ callback: @escaping (OpButtonSessionListener) -> Void) {
        listenerLock.lock()
        let listeners = sessionListeners
        listenerLock.unlock()
        let deliver = { listeners.forEach(callback) }
        if Thread.isMainThread { deliver() }
        else { DispatchQueue.main.async(execute: deliver) }
    }

    private func notifyConnecting() { notifySessionListeners { $0.onOpButtonSessionConnecting() } }
    private func notifyWaitingApproval(_ requestId: String) {
        notifySessionListeners { $0.onOpButtonSessionWaitingApproval(requestId) }
    }
    private func notifySessionStarted(_ token: String) {
        notifySessionListeners { $0.onOpButtonSessionStarted(token) }
    }
    private func notifySessionClosed() { notifySessionListeners { $0.onOpButtonSessionClosed() } }
    private func notifyRejected() { notifySessionListeners { $0.onOpButtonSessionRejected() } }
    private func notifyAuthFailed() { notifySessionListeners { $0.onOpButtonSessionAuthFailed() } }
    private func notifyError(_ error: OpButtonError) { notifySessionListeners { $0.onOpButtonSessionError(error) } }

    func acknowledgeAction(_ actionId: String, _ payload: [String: Any]?) {
        lock.lock()
        let token = sessionToken
        lock.unlock()
        if let token = token { acknowledgeForSession(token, actionId: actionId, payload: payload) }
    }

    private func acknowledgeForSession(_ token: String, actionId: String, payload: [String: Any]?) {
        workQueue?.async { [weak self] in
            guard let self = self, self.isCurrentSession(token) else { return }
            do { try self.httpClient.acknowledgeAction(sessionToken: token, actionId: actionId, ackPayload: payload) }
            catch { OpButtonLog.e("Failed to acknowledge action", error) }
        }
    }
}
