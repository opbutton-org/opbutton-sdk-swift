import Foundation

/// An outbox baseline advances only when its immutable snapshot is accepted.
final class OpButtonAttributeJournal {
    private var acknowledged: [String: Data] = [:]
    private let lock = NSLock()

    func snapshot(_ values: [String: Any]) -> [String: Any] {
        lock.lock()
        defer { lock.unlock() }
        var changed: [String: Any] = [:]
        for (key, value) in Self.capture(values) {
            if Self.encode(value) != acknowledged[key] { changed[key] = value }
        }
        return changed
    }

    func acknowledge(_ snapshot: [String: Any]?) {
        guard let snapshot = snapshot else { return }
        lock.lock()
        defer { lock.unlock() }
        for (key, value) in snapshot { acknowledged[key] = Self.encode(value) }
    }

    static func capture(_ values: [String: Any]) -> [String: Any] {
        var captured: [String: Any] = [:]
        for (key, value) in values {
            guard let data = encode(value),
                  let copy = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                OpButtonLog.w("Invalid session attribute: %@", key)
                continue
            }
            captured[key] = copy["value"]
        }
        return captured
    }

    private static func encode(_ value: Any) -> Data? {
        return try? JSONSerialization.data(withJSONObject: ["value": value], options: [.sortedKeys])
    }
}
