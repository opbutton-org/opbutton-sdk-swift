import Foundation

public final class OpButtonLabel: OpButtonWidget {
    init(ui: OpButtonUI, text: String) {
        super.init(ui: ui, type: "label")
        put("text", text)
    }

    @discardableResult
    public func text(_ text: String) -> OpButtonLabel {
        put("text", text)
        return self
    }

    @discardableResult
    public func color(_ color: String) -> OpButtonLabel {
        put("color", color)
        return self
    }

    @discardableResult
    public func textProvider(_ provider: OpButtonValueProvider?) -> OpButtonLabel {
        setProvider("text", provider)
        return self
    }
}
