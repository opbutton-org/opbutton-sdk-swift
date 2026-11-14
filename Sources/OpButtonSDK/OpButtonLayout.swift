import Foundation

public final class OpButtonLayout {
    public enum Direction: String {
        case vertical = "vertical"
        case horizontal = "horizontal"
    }

    private let ui: OpButtonUI
    public let direction: Direction
    private var children: [Any] = []

    init(ui: OpButtonUI, direction: Direction) {
        self.ui = ui
        self.direction = direction
    }

    // MARK: - Sub-layouts

    @discardableResult
    public func addVertical() -> OpButtonLayout {
        let sub = OpButtonLayout(ui: ui, direction: .vertical)
        children.append(sub)
        ui.incrementRevision()
        return sub
    }

    @discardableResult
    public func addHorizontal() -> OpButtonLayout {
        let sub = OpButtonLayout(ui: ui, direction: .horizontal)
        children.append(sub)
        ui.incrementRevision()
        return sub
    }

    @discardableResult
    public func addCollapsible(_ title: String) -> OpButtonLayout {
        let collapsible = CollapsibleElement(ui: ui, title: title)
        children.append(collapsible)
        ui.incrementRevision()
        return collapsible.content
    }

    // MARK: - Padding

    @discardableResult
    public func addPadding(_ weight: Double) -> OpButtonLayout {
        children.append(PaddingElement(weight: weight))
        ui.incrementRevision()
        return self
    }

    // MARK: - Widgets

    @discardableResult
    public func addButton(_ label: String) -> OpButtonButton {
        let w = OpButtonButton(ui: ui, label: label)
        children.append(w)
        ui.incrementRevision()
        return w
    }

    @discardableResult
    public func addLabel(_ text: String) -> OpButtonLabel {
        let w = OpButtonLabel(ui: ui, text: text)
        children.append(w)
        ui.incrementRevision()
        return w
    }

    @discardableResult
    public func addStat(_ label: String) -> OpButtonStat {
        let w = OpButtonStat(ui: ui, label: label)
        children.append(w)
        ui.incrementRevision()
        return w
    }

    @discardableResult
    public func addSwitch(_ label: String) -> OpButtonSwitch {
        let w = OpButtonSwitch(ui: ui, label: label)
        children.append(w)
        ui.incrementRevision()
        return w
    }

    @discardableResult
    public func addInput(_ label: String) -> OpButtonInput {
        let w = OpButtonInput(ui: ui, label: label)
        children.append(w)
        ui.incrementRevision()
        return w
    }

    @discardableResult
    public func addSelect(_ label: String) -> OpButtonSelect {
        let w = OpButtonSelect(ui: ui, label: label)
        children.append(w)
        ui.incrementRevision()
        return w
    }

    @discardableResult
    public func addTextarea(_ label: String) -> OpButtonTextarea {
        let w = OpButtonTextarea(ui: ui, label: label)
        children.append(w)
        ui.incrementRevision()
        return w
    }

    @discardableResult
    public func addTable(_ label: String) -> OpButtonTable {
        let w = OpButtonTable(ui: ui, label: label)
        children.append(w)
        ui.incrementRevision()
        return w
    }

    @discardableResult
    public func addLogs(_ label: String) -> OpButtonLogs {
        let w = OpButtonLogs(ui: ui, label: label)
        children.append(w)
        ui.incrementRevision()
        return w
    }

    // MARK: - Serialization

    func toJson() -> [String: Any] {
        var childrenArr: [[String: Any]] = []

        for child in children {
            if let layout = child as? OpButtonLayout {
                childrenArr.append(layout.toJson())
            } else if let widget = child as? OpButtonWidget {
                childrenArr.append(widget.toJson())
            } else if let padding = child as? PaddingElement {
                childrenArr.append(padding.toJson())
            } else if let collapsible = child as? CollapsibleElement {
                childrenArr.append(collapsible.toJson())
            }
        }

        return [
            "type": "layout",
            "direction": direction.rawValue,
            "children": childrenArr
        ]
    }
}

// MARK: - Helper Elements

private final class PaddingElement {
    let weight: Double

    init(weight: Double) {
        self.weight = weight
    }

    func toJson() -> [String: Any] {
        return [
            "type": "padding",
            "weight": weight
        ]
    }
}

private final class CollapsibleElement {
    let title: String
    let content: OpButtonLayout

    init(ui: OpButtonUI, title: String) {
        self.title = title
        self.content = OpButtonLayout(ui: ui, direction: .vertical)
    }

    func toJson() -> [String: Any] {
        let contentJson = content.toJson()
        return [
            "type": "collapsible",
            "title": title,
            "children": contentJson["children"] ?? []
        ]
    }
}
