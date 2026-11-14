import Foundation

public final class OpButtonTable: OpButtonWidget {
    init(ui: OpButtonUI, label: String) {
        super.init(ui: ui, type: "table")
        put("label", label)
    }

    @discardableResult
    public func columns(_ columns: [[String]]) -> OpButtonTable {
        let arr = columns.map { col -> [String: String] in
            return ["key": col[0], "label": col[1]]
        }
        put("columns", arr)
        return self
    }

    @discardableResult
    public func rows(_ rows: [[String: Any]]) -> OpButtonTable {
        put("rows", rows)
        return self
    }
}
