import Foundation

public enum OpButtonJsonError: Error {
    case invalidElement
    case invalidLayout
    case invalidChildren
    case excessiveNesting
}

public typealias OpButtonJsonCallback = (String, OpButtonAction) -> Void

final class OpButtonJsonElement: OpButtonElement {
    private var json: [String: Any]
    private let identifier: String?
    private var children: [OpButtonJsonElement] = []

    init(ui: OpButtonUI, description: [String: Any], depth: Int = 0) throws {
        guard depth <= 32 else { throw OpButtonJsonError.excessiveNesting }
        guard let type = description["type"] as? String, !type.isEmpty else { throw OpButtonJsonError.invalidElement }

        json = description
        identifier = description["id"] as? String
        super.init(ui: ui)

        if let values = description["children"] {
            guard let values = values as? [[String: Any]] else { throw OpButtonJsonError.invalidChildren }
            json["children"] = []
            children = try values.map { try OpButtonJsonElement(ui: ui, description: $0, depth: depth + 1) }
        }
    }

    func attach(_ callback: OpButtonJsonCallback?) {
        if let identifier = identifier, !identifier.isEmpty, let callback = callback {
            ui.registerCallback(internalId) { action in callback(identifier, action) }
        }

        children.forEach { $0.attach(callback) }
    }

    override func detach() {
        children.forEach { $0.detach() }
        super.detach()
    }

    func toJson() -> [String: Any] {
        var result = json

        if result["children"] != nil {
            result["children"] = children.map { $0.toJson() }
        }

        return decorate(result)
    }
}
