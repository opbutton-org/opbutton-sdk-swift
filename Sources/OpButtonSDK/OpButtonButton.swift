import Foundation

public final class OpButtonButton: OpButtonWidget {
    init(ui: OpButtonUI, label: String) {
        super.init(ui: ui, type: "button")
        put("label", label)
    }

    @discardableResult
    public func variant(_ variant: String) -> OpButtonButton {
        put("variant", variant)
        return self
    }

    @discardableResult
    public func color(_ color: String) -> OpButtonButton {
        put("color", color)
        return self
    }

    @discardableResult
    public func disabled(_ disabled: Bool) -> OpButtonButton {
        put("disabled", disabled)
        return self
    }

    @discardableResult
    public func onClick(_ callback: OpButtonWidgetCallback?) -> OpButtonButton {
        ui.registerCallback(internalId, callback)
        return self
    }
}
