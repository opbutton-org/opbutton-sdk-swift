import Foundation

public final class OpButtonTab {
    private let ui: OpButtonUI
    private let internalId: Int
    public private(set) var id: String
    public let title: String
    private var layout: OpButtonLayout?

    init(ui: OpButtonUI, title: String) {
        self.ui = ui
        self.internalId = ui.nextId()
        self.id = "tab-\(internalId)"
        self.title = title
    }

    @discardableResult
    public func setId(_ id: String) -> OpButtonTab {
        self.id = id
        return self
    }

    public func getLayout() -> OpButtonLayout? {
        return layout
    }

    @discardableResult
    public func vertical() -> OpButtonLayout {
        let l = OpButtonLayout(ui: ui, direction: .vertical)
        layout = l
        return l
    }

    @discardableResult
    public func horizontal() -> OpButtonLayout {
        let l = OpButtonLayout(ui: ui, direction: .horizontal)
        layout = l
        return l
    }

    func toJson() -> [String: Any] {
        var json: [String: Any] = [
            "id": internalId,
            "title": title
        ]
        if let layout = layout {
            json["layout"] = layout.toJson()
        }
        return json
    }
}
