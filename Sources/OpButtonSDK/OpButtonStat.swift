import Foundation

public final class OpButtonStat: OpButtonWidget {
    init(ui: OpButtonUI, label: String) {
        super.init(ui: ui, type: "stat")
        put("label", label)
    }

    @discardableResult
    public func value(_ value: String) -> OpButtonStat {
        put("value", value)
        return self
    }

    @discardableResult
    public func unit(_ unit: String) -> OpButtonStat {
        put("unit", unit)
        return self
    }

    @discardableResult
    public func valueProvider(_ provider: OpButtonValueProvider?) -> OpButtonStat {
        setProvider("value", provider)
        return self
    }
}
