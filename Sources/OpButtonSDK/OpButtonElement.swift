import Foundation

/// Sizing shared by retained widgets and layouts. Dimensions are CSS pixels.
public class OpButtonElement {
    let ui: OpButtonUI
    public let internalId: Int
    private var placement: [String: Any] = [:]

    init(ui: OpButtonUI) {
        self.ui = ui
        self.internalId = ui.nextId()
    }

    static func dimension(_ value: Double, positive: Bool = false) -> Double {
        precondition(value.isFinite && value <= 4096 && (positive ? value > 0 : value >= 0))
        return value
    }

    static func alignment(_ value: String) -> String {
        precondition(["start", "center", "end", "stretch"].contains(value))
        return value
    }

    @discardableResult
    private func place(_ key: String, _ value: Any) -> Self {
        placement[key] = value
        ui.incrementRevision()
        return self
    }

    @discardableResult public func width(_ pixels: Double) -> Self { place("width", Self.dimension(pixels, positive: true)) }
    @discardableResult public func contentWidth() -> Self { place("width", "content") }
    @discardableResult public func fill(_ weight: Double = 1) -> Self {
        place("weight", Self.dimension(weight, positive: true))
        return place("width", "fill")
    }
    @discardableResult public func minWidth(_ pixels: Double) -> Self { place("minWidth", Self.dimension(pixels)) }
    @discardableResult public func maxWidth(_ pixels: Double) -> Self { place("maxWidth", Self.dimension(pixels, positive: true)) }
    @discardableResult public func alignSelf(_ value: String) -> Self { place("alignSelf", Self.alignment(value)) }

    func loadPlacement(_ description: [String: Any]) {
        placement = description["placement"] as? [String: Any] ?? [:]
    }

    func detach() { ui.registerCallback(internalId, nil) }

    func decorate(_ json: [String: Any]) -> [String: Any] {
        var result = json
        result["id"] = internalId
        if !placement.isEmpty { result["placement"] = placement }
        return result
    }
}
