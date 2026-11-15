import Foundation

protocol OpButtonPollTransport {
    func submitPanel(sessionToken: String, layout: [String: Any]) throws -> [String: Any]
    func pollActions(sessionToken: String, changedAttributes: [String: Any]?,
                     logs: [OpButtonLogEntry], metrics: [OpButtonMetricEntry]) throws -> [String: Any]
}

protocol OpButtonPollState {
    func capture() -> OpButtonPollSnapshot
    func panelSent(_ snapshot: OpButtonPollSnapshot)
    func attributesSent(_ snapshot: OpButtonPollSnapshot)
}

struct OpButtonPollSnapshot {
    let attributes: [String: Any]?
    let panel: OpButtonPanelSnapshot?
}

/// A poll is a delivery transaction; an unfinished telemetry receipt rolls back.
final class OpButtonPollDelivery {
    private let transport: OpButtonPollTransport
    private let state: OpButtonPollState
    private let telemetry: OpButtonTelemetry
    private let isCurrent: (String) -> Bool
    private let onPanelError: (OpButtonError) -> Void

    init(transport: OpButtonPollTransport, state: OpButtonPollState, telemetry: OpButtonTelemetry,
         isCurrent: @escaping (String) -> Bool, onPanelError: @escaping (OpButtonError) -> Void) {
        self.transport = transport
        self.state = state
        self.telemetry = telemetry
        self.isCurrent = isCurrent
        self.onPanelError = onPanelError
    }

    func exchange(_ token: String) throws -> [String: Any] {
        let snapshot = state.capture()
        if let panel = snapshot.panel {
            do {
                _ = try transport.submitPanel(sessionToken: token, layout: panel.layout)
                if isCurrent(token) { state.panelSent(snapshot) }
            } catch {
                OpButtonLog.e("Failed to submit UI", error)
                onPanelError(OpButtonError("Failed to submit UI", cause: error))
            }
        }

        let batch = telemetry.capture()
        defer { batch.rollback() }
        let response = try transport.pollActions(sessionToken: token, changedAttributes: snapshot.attributes,
                                                logs: batch.logs, metrics: batch.metrics)
        if isCurrent(token) { state.attributesSent(snapshot) }
        batch.commit()
        return response
    }

    func probe(_ token: String) throws -> [String: Any] {
        return try transport.pollActions(sessionToken: token, changedAttributes: nil, logs: [], metrics: [])
    }
}
