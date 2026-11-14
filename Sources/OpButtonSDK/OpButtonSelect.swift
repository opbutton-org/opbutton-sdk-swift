import Foundation

public final class OpButtonSelect: OpButtonWidget {
    init(ui: OpButtonUI, label: String) {
        super.init(ui: ui, type: "select")
        put("label", label)
    }

    @discardableResult
    public func options(_ options: [[String]]) -> OpButtonSelect {
        let arr = options.map { opt -> [String: String] in
            return ["value": opt[0], "label": opt[1]]
        }
        put("options", arr)
        return self
    }

    @discardableResult
    public func defaultValue(_ value: String) -> OpButtonSelect {
        put("defaultValue", value)
        return self
    }

    @discardableResult
    public func onChange(_ callback: OpButtonWidgetCallback?) -> OpButtonSelect {
        ui.registerCallback(internalId, callback)
        return self
    }

    @discardableResult
    public func onChange(_ callback: @escaping (OpButtonSelectAction) -> Void) -> OpButtonSelect {
        ui.registerCallback(internalId) { action in callback(OpButtonSelectAction(action)) }
        return self
    }
}
