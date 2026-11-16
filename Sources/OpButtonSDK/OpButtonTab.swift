import Foundation

public final class OpButtonTab {
    private let ui: OpButtonUI
    private let internalId: Int
    public private(set) var id: String
    public private(set) var title: String
    private var layout: OpButtonLayout?

    init(ui: OpButtonUI, identifier: String) {
        self.ui = ui
        self.internalId = ui.nextId()
        self.id = identifier
        self.title = identifier
    }

    @discardableResult
    public func setId(_ id: String) -> OpButtonTab {
        self.id = id
        return self
    }

    @discardableResult
    public func setName(_ name: String) -> OpButtonTab {
        title = name
        ui.incrementRevision()
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

    @discardableResult
    public func setJson(_ description: [String: Any], onAction: OpButtonJsonCallback? = nil) throws -> OpButtonLayout {
        let data = try JSONSerialization.data(withJSONObject: description)
        guard let snapshot = try JSONSerialization.jsonObject(with: data) as? [String: Any] else { throw OpButtonJsonError.invalidLayout }
        let next = try OpButtonLayout.fromJson(ui: ui, description: snapshot, callback: onAction)
        layout?.detach()
        layout = next
        ui.incrementRevision()
        return next
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
