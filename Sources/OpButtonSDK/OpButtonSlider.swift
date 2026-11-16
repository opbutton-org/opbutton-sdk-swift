import Foundation

public final class OpButtonSlider: OpButtonWidget {
    init(ui: OpButtonUI, label: String) {
        super.init(ui: ui, type: "slider")
        put("label", label)
    }

    @discardableResult public func range(_ min: Double, _ max: Double, _ step: Double) -> Self {
        precondition(min.isFinite && max.isFinite && step.isFinite && (max - min).isFinite && min < max && step > 0 && step <= max - min)
        put("min", min); put("max", max); put("step", step); return self
    }
    @discardableResult public func defaultValue(_ value: Double) -> Self {
        precondition(value.isFinite); put("defaultValue", value); return self
    }
    @discardableResult public func unit(_ value: String) -> Self { put("unit", value); return self }
    @discardableResult public func disabled(_ value: Bool) -> Self { put("disabled", value); return self }

    @discardableResult
    public func onChange(_ callback: OpButtonWidgetCallback?) -> OpButtonSlider {
        ui.registerCallback(internalId, callback)
        return self
    }

    @discardableResult
    public func onChange(_ callback: @escaping (OpButtonSliderAction) -> Void) -> OpButtonSlider {
        ui.registerCallback(internalId) { action in callback(OpButtonSliderAction(action)) }
        return self
    }
}
