import Foundation

public final class OpButtonLogs: OpButtonWidget {
    init(ui: OpButtonUI, label: String) {
        super.init(ui: ui, type: "logs")
        put("label", label)
    }

    @discardableResult
    public func maxLines(_ maxLines: Int) -> OpButtonLogs {
        put("maxLines", maxLines)
        return self
    }
}
