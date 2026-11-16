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
        layout?.detach()
        ui.incrementRevision()
        layout = l
        return l
    }

    @discardableResult
    public func horizontal() -> OpButtonLayout {
        let l = OpButtonLayout(ui: ui, direction: .horizontal)
        layout?.detach()
        ui.incrementRevision()
        layout = l
        return l
    }

    @discardableResult
    public func grid() -> OpButtonLayout {
        let child = OpButtonLayout(ui: ui, direction: .grid)
        layout?.detach()
        ui.incrementRevision()
        layout = child
        return child
    }

    func detach() { layout?.detach() }

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
