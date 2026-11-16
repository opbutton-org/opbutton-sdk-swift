import Foundation

public final class OpButtonRadioGroup: OpButtonWidget {
    init(ui: OpButtonUI, label: String) {
        super.init(ui: ui, type: "radio")
        put("label", label)
    }

    @discardableResult
    public func options(_ options: [[String]]) -> OpButtonRadioGroup {
        let arr = options.map { opt -> [String: String] in
            return ["value": opt[0], "label": opt[1]]
        }
        put("options", arr)
        return self
    }

    @discardableResult
    public func defaultValue(_ value: String) -> OpButtonRadioGroup {
        put("defaultValue", value)
        return self
    }

    @discardableResult public func disabled(_ value: Bool) -> Self { put("disabled", value); return self }
    @discardableResult public func optionDirection(_ value: String) -> Self {
        precondition(["horizontal", "vertical"].contains(value)); put("optionDirection", value); return self
    }

    @discardableResult
    public func onChange(_ callback: OpButtonWidgetCallback?) -> OpButtonRadioGroup {
        ui.registerCallback(internalId, callback)
        return self
    }

    @discardableResult
    public func onChange(_ callback: @escaping (OpButtonRadioGroupAction) -> Void) -> OpButtonRadioGroup {
        ui.registerCallback(internalId) { action in callback(OpButtonRadioGroupAction(action)) }
        return self
    }
}
