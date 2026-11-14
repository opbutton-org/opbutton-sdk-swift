import Foundation

public final class OpButtonSwitch: OpButtonWidget {
    init(ui: OpButtonUI, label: String) {
        super.init(ui: ui, type: "switch")
        put("label", label)
    }

    @discardableResult
    public func defaultValue(_ value: Bool) -> OpButtonSwitch {
        put("defaultValue", value)
        return self
    }

    @discardableResult
    public func onChange(_ callback: OpButtonWidgetCallback?) -> OpButtonSwitch {
        ui.registerCallback(internalId, callback)
        return self
    }

    @discardableResult
    public func onChange(_ callback: @escaping (OpButtonSwitchAction) -> Void) -> OpButtonSwitch {
        ui.registerCallback(internalId) { action in callback(OpButtonSwitchAction(action)) }
        return self
    }
}
