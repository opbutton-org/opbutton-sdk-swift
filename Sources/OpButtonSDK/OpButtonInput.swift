import Foundation

public final class OpButtonInput: OpButtonWidget {
    init(ui: OpButtonUI, label: String) {
        super.init(ui: ui, type: "input")
        put("label", label)
    }

    @discardableResult
    public func inputType(_ type: String) -> OpButtonInput {
        put("inputType", type)
        return self
    }

    @discardableResult
    public func defaultValue(_ value: String) -> OpButtonInput {
        put("defaultValue", value)
        return self
    }

    @discardableResult
    public func placeholder(_ placeholder: String) -> OpButtonInput {
        put("placeholder", placeholder)
        return self
    }

    @discardableResult
    public func onSubmit(_ callback: OpButtonWidgetCallback?) -> OpButtonInput {
        ui.registerCallback(internalId, callback)
        return self
    }

    @discardableResult
    public func onSubmit(_ callback: @escaping (OpButtonInputAction) -> Void) -> OpButtonInput {
        ui.registerCallback(internalId) { action in callback(OpButtonInputAction(action)) }
        return self
    }
}
