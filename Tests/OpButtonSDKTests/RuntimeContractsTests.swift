import XCTest
@testable import OpButtonSDK

final class RuntimeContractsTests: XCTestCase {
    private var http: OpButtonHttpClient!
    private var metrics: OpButtonMetrics!
    private var telemetry: OpButtonTelemetry!
    private var state: State!
    private var peer: Peer!
    private var delivery: OpButtonPollDelivery!
    private var current = true
    private var panelErrors = 0

    override func setUp() {
        super.setUp()
        http = OpButtonHttpClient(baseUrl: "https://opbutton.invalid", apiToken: "test")
        metrics = OpButtonMetrics()
        telemetry = OpButtonTelemetry(logConfig: OpButtonLogConfig(), httpClient: http, metrics: metrics)
        state = State()
        peer = Peer()
        delivery = OpButtonPollDelivery(transport: peer, state: state, telemetry: telemetry,
            isCurrent: { [weak self] _ in self?.current ?? false },
            onPanelError: { [weak self] _ in self?.panelErrors += 1 })
    }

    override func tearDown() {
        peer.onPoll = nil
        http.shutdown()
        super.tearDown()
    }

    func testFailedPollRestoresTelemetryInOrderAndDoesNotCommitAttributes() throws {
        telemetry.bufferLog(OpButtonLogEntry(level: .info, message: "first"))
        metrics.record(.cpuUsage, 1)
        peer.onPoll = { [self] in
            telemetry.bufferLog(OpButtonLogEntry(level: .info, message: "later"))
            metrics.record(.cpuUsage, 2)
            state.values["level"] = 2
        }
        peer.failPoll = true
        XCTAssertThrowsError(try delivery.exchange("session"))
        XCTAssertEqual(state.attributesAccepted, 0)
        peer.onPoll = nil
        peer.failPoll = false
        _ = try delivery.exchange("session")
        XCTAssertEqual(peer.logs.map { $0.message }, ["first", "later"])
        XCTAssertEqual(peer.samples.map { $0.value }, [1, 2])
        XCTAssertEqual(peer.attributes?["level"] as? Int, 2)
        XCTAssertTrue(state.journal.snapshot(state.values).isEmpty)
        let empty = telemetry.capture()
        XCTAssertTrue(empty.logs.isEmpty)
        empty.rollback()
    }

    func testFailedPanelDoesNotBlockPollingOrAcknowledgeThePanel() throws {
        state.panel = try XCTUnwrap(OpButtonPanelSnapshot(["revision": 7]))
        peer.failPanel = true
        _ = try delivery.exchange("session")
        XCTAssertEqual(state.panelsAccepted, 0)
        XCTAssertEqual(state.attributesAccepted, 1)
        XCTAssertEqual(peer.polls, 1)
        XCTAssertEqual(panelErrors, 1)
    }

    func testLateResponseDoesNotAcknowledgeAnotherSession() throws {
        peer.onPoll = { [self] in current = false }
        _ = try delivery.exchange("old-session")
        XCTAssertEqual(state.attributesAccepted, 0)
        XCTAssertFalse(state.journal.snapshot(state.values).isEmpty)
    }

    func testProbePreservesTheOutboxAndReturnsTheResponse() throws {
        telemetry.bufferLog(OpButtonLogEntry(level: .info, message: "pending"))
        XCTAssertEqual(try delivery.probe("session")["probe"] as? Bool, true)
        XCTAssertEqual(state.captures, 0)
        XCTAssertNil(peer.attributes)
        XCTAssertTrue(peer.logs.isEmpty)
        let pending = telemetry.capture()
        XCTAssertEqual(pending.logs.count, 1)
        pending.rollback()
    }

    func testBatchSettlementIsIdempotentAndCommittedDataStaysConsumed() {
        telemetry.bufferLog(OpButtonLogEntry(level: .info, message: "pending"))
        let first = telemetry.capture()
        first.rollback()
        first.rollback()
        let retry = telemetry.capture()
        XCTAssertEqual(retry.logs.count, 1)
        retry.commit()
        retry.commit()
        retry.rollback()
        let empty = telemetry.capture()
        XCTAssertTrue(empty.logs.isEmpty)
        empty.rollback()
    }

    func testClosedTransportRejectsNewRequestsWithoutAnObjectiveCException() {
        http.shutdown()
        http.shutdown()
        XCTAssertThrowsError(try http.pollActions(sessionToken: "session", changedAttributes: nil, logs: [], metrics: []))
    }

    func testReservedCommandsAreExclusiveAndKeepTheirCapturedSession() {
        var calls: [String] = []
        var commands: [OpButtonActionType: OpButtonActionRouter.Command] = [.liveStart: { _, token in calls.append(token) }]
        let listener = Listener { _ in calls.append("listener") }
        let router = OpButtonActionRouter(commands: commands, widgets: { _ in calls.append("widget") }, listeners: { [listener] })
        commands.removeAll()
        router.dispatch(action(.liveStart), token: "original-session")
        XCTAssertEqual(calls, ["original-session"])
    }

    func testObserversCanRemoveThemselvesWithoutSkippingTheNextObserver() {
        var calls: [String] = []
        var listeners: [OpButtonActionListener] = []
        listeners.append(Listener { _ in calls.append("first"); listeners.removeFirst() })
        listeners.append(Listener { _ in calls.append("second") })
        let router = OpButtonActionRouter(commands: [:], widgets: { _ in calls.append("widget") }, listeners: { listeners })
        router.dispatch(action(.click), token: "session")
        XCTAssertEqual(calls, ["widget", "first", "second"])
    }

    private func action(_ type: OpButtonActionType) -> OpButtonAction {
        return OpButtonAction(id: "action", sessionId: "session", widgetId: 1, actionType: type, status: .delivered, payload: nil)
    }

    private final class Listener: OpButtonActionListener {
        private let callback: (OpButtonAction) -> Void
        init(_ callback: @escaping (OpButtonAction) -> Void) { self.callback = callback }
        func onOpButtonActionReceived(_ action: OpButtonAction) { callback(action) }
    }

    private final class State: OpButtonPollState {
        let journal = OpButtonAttributeJournal()
        var values: [String: Any] = ["level": 1]
        var panel: OpButtonPanelSnapshot?
        var captures = 0
        var panelsAccepted = 0
        var attributesAccepted = 0

        func capture() -> OpButtonPollSnapshot {
            captures += 1
            return OpButtonPollSnapshot(attributes: journal.snapshot(values), panel: panel)
        }
        func panelSent(_ snapshot: OpButtonPollSnapshot) { panelsAccepted += 1 }
        func attributesSent(_ snapshot: OpButtonPollSnapshot) {
            attributesAccepted += 1
            journal.acknowledge(snapshot.attributes)
        }
    }

    private final class Peer: OpButtonPollTransport {
        var onPoll: (() -> Void)?
        var failPanel = false
        var failPoll = false
        var polls = 0
        var attributes: [String: Any]?
        var logs: [OpButtonLogEntry] = []
        var samples: [OpButtonMetricEntry] = []

        func submitPanel(sessionToken: String, layout: [String: Any]) throws -> [String: Any] {
            if failPanel { throw OpButtonError(httpCode: 503, "Panel unavailable") }
            return [:]
        }
        func pollActions(sessionToken: String, changedAttributes: [String: Any]?, logs: [OpButtonLogEntry], metrics: [OpButtonMetricEntry]) throws -> [String: Any] {
            polls += 1
            attributes = changedAttributes
            self.logs = logs
            samples = metrics
            onPoll?()
            if failPoll { throw OpButtonError(httpCode: 503, "Poll unavailable") }
            return ["probe": true]
        }
    }
}
