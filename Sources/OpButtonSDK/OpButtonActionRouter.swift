import Foundation

/// Routes reserved commands exclusively, then publishes application actions to observers.
final class OpButtonActionRouter {
    typealias Command = (OpButtonAction, String) -> Void
    private let commands: [OpButtonActionType: Command]
    private let widgets: (OpButtonAction) -> Void
    private let listeners: () -> [OpButtonActionListener]

    init(commands: [OpButtonActionType: Command], widgets: @escaping (OpButtonAction) -> Void,
         listeners: @escaping () -> [OpButtonActionListener]) {
        self.commands = commands
        self.widgets = widgets
        self.listeners = listeners
    }

    func dispatch(_ action: OpButtonAction, token: String) {
        if let command = commands[action.actionType] {
            command(action, token)
            return
        }
        widgets(action)
        for listener in listeners() { listener.onOpButtonActionReceived(action) }
    }
}
