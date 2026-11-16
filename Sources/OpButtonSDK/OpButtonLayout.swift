import Foundation

public final class OpButtonLayout: OpButtonElement {
    public enum Direction: String { case vertical, horizontal, grid }
    public let direction: Direction
    private var children: [Any] = []
    private var settings: [String: Any] = [:]
    init(ui: OpButtonUI, direction: Direction) { self.direction = direction; super.init(ui: ui) }

    @discardableResult private func option(_ key: String, _ value: Any) -> Self {
        settings[key] = value; ui.incrementRevision(); return self
    }
    @discardableResult public func gap(_ pixels: Double) -> Self { option("gap", Self.dimension(pixels)) }
    @discardableResult public func padding(_ pixels: Double) -> Self { option("padding", Self.dimension(pixels)) }
    @discardableResult public func align(_ value: String) -> Self { option("align", Self.alignment(value)) }
    @discardableResult public func justify(_ value: String) -> Self {
        precondition(["start", "center", "end", "space-between"].contains(value)); return option("justify", value)
    }
    @discardableResult public func wrap(_ value: Bool) -> Self { option("wrap", value) }
    @discardableResult public func density(_ value: String) -> Self {
        precondition(["compact", "comfortable"].contains(value)); return option("density", value)
    }
    @discardableResult public func columns(_ value: Int) -> Self {
        precondition((1...12).contains(value)); return option("gridColumns", value)
    }
    @discardableResult public func minCellWidth(_ pixels: Double) -> Self { option("minCellWidth", Self.dimension(pixels, positive: true)) }
    @discardableResult public func title(_ value: String) -> Self { option("title", value) }
    private func addLayout(_ direction: Direction) -> OpButtonLayout {
        let child = OpButtonLayout(ui: ui, direction: direction)
        children.append(child); ui.incrementRevision(); return child
    }
    @discardableResult public func addVertical() -> OpButtonLayout { addLayout(.vertical) }
    @discardableResult public func addHorizontal() -> OpButtonLayout { addLayout(.horizontal) }
    @discardableResult public func addGrid() -> OpButtonLayout { addLayout(.grid) }
    @discardableResult public func addGroup(_ title: String) -> OpButtonLayout { addVertical().title(title) }
    @discardableResult public func addPadding(_ weight: Double) -> Self {
        children.append(PaddingElement(ui: ui, weight: weight))
        ui.incrementRevision(); return self
    }
    @discardableResult public func addCollapsible(_ title: String) -> OpButtonLayout {
        let child = CollapsibleElement(ui: ui, title: title)
        children.append(child); ui.incrementRevision(); return child.content
    }
    @discardableResult
    public func addButton(_ label: String) -> OpButtonButton {
        let widget = OpButtonButton(ui: ui, label: label)
        children.append(widget)
        ui.incrementRevision()
        return widget
    }

    @discardableResult
    public func addLabel(_ label: String) -> OpButtonLabel {
        let widget = OpButtonLabel(ui: ui, text: label)
        children.append(widget)
        ui.incrementRevision()
        return widget
    }

    @discardableResult
    public func addStat(_ label: String) -> OpButtonStat {
        let widget = OpButtonStat(ui: ui, label: label)
        children.append(widget)
        ui.incrementRevision()
        return widget
    }

    @discardableResult
    public func addSwitch(_ label: String) -> OpButtonSwitch {
        let widget = OpButtonSwitch(ui: ui, label: label)
        children.append(widget)
        ui.incrementRevision()
        return widget
    }

    @discardableResult
    public func addInput(_ label: String) -> OpButtonInput {
        let widget = OpButtonInput(ui: ui, label: label)
        children.append(widget)
        ui.incrementRevision()
        return widget
    }

    @discardableResult
    public func addSelect(_ label: String) -> OpButtonSelect {
        let widget = OpButtonSelect(ui: ui, label: label)
        children.append(widget)
        ui.incrementRevision()
        return widget
    }

    @discardableResult
    public func addTextarea(_ label: String) -> OpButtonTextarea {
        let widget = OpButtonTextarea(ui: ui, label: label)
        children.append(widget)
        ui.incrementRevision()
        return widget
    }

    @discardableResult
    public func addTable(_ label: String) -> OpButtonTable {
        let widget = OpButtonTable(ui: ui, label: label)
        children.append(widget)
        ui.incrementRevision()
        return widget
    }

    @discardableResult
    public func addLogs(_ label: String) -> OpButtonLogs {
        let widget = OpButtonLogs(ui: ui, label: label)
        children.append(widget)
        ui.incrementRevision()
        return widget
    }

    @discardableResult
    public func addRadioGroup(_ label: String) -> OpButtonRadioGroup {
        let widget = OpButtonRadioGroup(ui: ui, label: label)
        children.append(widget)
        ui.incrementRevision()
        return widget
    }

    @discardableResult
    public func addSlider(_ label: String) -> OpButtonSlider {
        let widget = OpButtonSlider(ui: ui, label: label)
        children.append(widget)
        ui.incrementRevision()
        return widget
    }

    static func fromJson(ui: OpButtonUI, description: [String: Any], callback: OpButtonJsonCallback?) throws -> OpButtonLayout {
        guard description["type"] as? String == "layout",
              let value = description["direction"] as? String,
              let direction = Direction(rawValue: value) else { throw OpButtonJsonError.invalidLayout }

        let layout = OpButtonLayout(ui: ui, direction: direction)
        layout.settings = description.filter { !["children", "id", "placement"].contains($0.key) }
        layout.loadPlacement(description)

        if let values = description["children"] {
            guard let values = values as? [[String: Any]] else { throw OpButtonJsonError.invalidChildren }
            let elements = try values.map { try OpButtonJsonElement(ui: ui, description: $0) }
            layout.children = elements
            elements.forEach { $0.attach(callback) }
        }

        return layout
    }

    override func detach() { children.forEach { ($0 as? OpButtonElement)?.detach() }; super.detach() }

    func toJson() -> [String: Any] {
        var json = settings
        json["type"] = "layout"; json["direction"] = direction.rawValue
        json["children"] = children.map { child -> [String: Any] in
            if let child = child as? OpButtonLayout { return child.toJson() }
            if let child = child as? OpButtonWidget { return child.toJson() }
            if let child = child as? OpButtonJsonElement { return child.toJson() }
            if let child = child as? PaddingElement { return child.toJson() }
            if let child = child as? CollapsibleElement { return child.toJson() }
            preconditionFailure("Unknown layout child")
        }
        return decorate(json)
    }
}

private final class PaddingElement: OpButtonElement {
    let weight: Double
    init(ui: OpButtonUI, weight: Double) { self.weight = weight; super.init(ui: ui) }
    func toJson() -> [String: Any] { decorate(["type": "padding", "weight": weight]) }
}
private final class CollapsibleElement: OpButtonElement {
    let title: String
    override func detach() { content.detach(); super.detach() }
    let content: OpButtonLayout
    init(ui: OpButtonUI, title: String) {
        self.title = title; content = OpButtonLayout(ui: ui, direction: .vertical); super.init(ui: ui)
    }
    func toJson() -> [String: Any] { decorate(["type": "collapsible", "title": title, "children": [content.toJson()]]) }
}
