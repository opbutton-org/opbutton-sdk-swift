import Foundation

/// Reads host-owned state and acknowledges only the captured values.
final class OpButtonHostState: OpButtonPollState {
    private let attributes: OpButtonSessionAttributes
    private let ui: OpButtonUI
    private let attributeJournal = OpButtonAttributeJournal()

    init(attributes: OpButtonSessionAttributes, ui: OpButtonUI) {
        self.attributes = attributes
        self.ui = ui
    }

    func initialPanel() -> OpButtonPanelSnapshot? { OpButtonMainThread.sync { ui.snapshot() } }

    func capture() -> OpButtonPollSnapshot {
        return OpButtonMainThread.sync {
            ui.pollValues()
            return OpButtonPollSnapshot(attributes: resolveChangedSessionAttributes(), panel: ui.hasUnsent ? ui.snapshot() : nil)
        }
    }

    func panelSent(_ snapshot: OpButtonPollSnapshot) {
        if let panel = snapshot.panel { ui.markSent(panel.revision) }
    }

    func attributesSent(_ snapshot: OpButtonPollSnapshot) { acknowledgeAll(snapshot.attributes) }
    func acknowledgeAll(_ values: [String: Any]?) { attributeJournal.acknowledge(values) }
    private func resolveDynamicSessionAttributes() -> [String: Any] {
        var values: [String: Any] = [:]
        for (key, provider) in attributes.dynamicAttributes {
            values[key] = provider() ?? NSNull()
        }
        return values
    }

    func resolveAllSessionAttributes() -> [String: Any] {
        return OpButtonMainThread.sync {
            var values = attributes.staticAttributes
            values.merge(resolveDynamicSessionAttributes()) { _, current in current }
            return OpButtonAttributeJournal.capture(values)
        }
    }

    private func resolveChangedSessionAttributes() -> [String: Any]? {
        return OpButtonMainThread.sync {
            attributeJournal.snapshot(resolveDynamicSessionAttributes())
        }
    }
}
