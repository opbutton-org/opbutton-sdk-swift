import Foundation

public final class OpButtonTextarea: OpButtonWidget {
    init(ui: OpButtonUI, label: String) {
        super.init(ui: ui, type: "textarea")
        put("label", label)
    }

    @discardableResult
    public func rows(_ rows: Int) -> OpButtonTextarea {
        put("rows", rows)
        return self
    }

    @discardableResult
    public func defaultValue(_ value: String) -> OpButtonTextarea {
        put("defaultValue", value)
        return self
    }

    @discardableResult
    public func onSubmit(_ callback: OpButtonWidgetCallback?) -> OpButtonTextarea {
        ui.registerCallback(internalId, callback)
        return self
    }

    @discardableResult
    public func onSubmit(_ callback: @escaping (OpButtonTextareaAction) -> Void) -> OpButtonTextarea {
        ui.registerCallback(internalId) { action in callback(OpButtonTextareaAction(action)) }
        return self
    }
}
