import Foundation

/// Composes media commands with a captured session; no command calls the global facade.
final class OpButtonLiveCommands {
    private let live: OpButtonLiveManager
    private let background: (@escaping () -> Void) -> Void
    private let isCurrent: (String) -> Bool
    private let acknowledge: (String, String, [String: Any]?) -> Void

    init(live: OpButtonLiveManager, background: @escaping (@escaping () -> Void) -> Void,
         isCurrent: @escaping (String) -> Bool, acknowledge: @escaping (String, String, [String: Any]?) -> Void) {
        self.live = live
        self.background = background
        self.isCurrent = isCurrent
        self.acknowledge = acknowledge
    }

    func commands() -> [OpButtonActionType: OpButtonActionRouter.Command] {
        return [
            .liveStart: { [self] action, token in stream(action, token: token, operation: live.start) },
            .liveUpdate: { [self] action, token in stream(action, token: token, operation: live.update) },
            .liveStop: { [self] action, token in acknowledge(token, action.id, live.stop()) },
            .liveTap: { [self] action, token in acknowledge(token, action.id, live.tap(action.payload)) },
            .liveLongPress: { [self] action, token in acknowledge(token, action.id, live.longPress(action.payload)) }
        ]
    }

    private func stream(_ action: OpButtonAction, token: String,
                        operation: @escaping (String, [String: Any]?) -> [String: Any]) {
        background { [self] in
            guard isCurrent(token) else { return }
            let result = operation(token, action.payload)
            if isCurrent(token) { acknowledge(token, action.id, result) }
        }
    }
}
