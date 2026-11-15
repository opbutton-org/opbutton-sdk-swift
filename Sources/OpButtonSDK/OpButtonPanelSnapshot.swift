import Foundation

/// A detached layout and the exact revision represented by its payload.
struct OpButtonPanelSnapshot {
    let revision: Int
    let layout: [String: Any]

    init?(_ value: [String: Any]) {
        guard let revision = value["revision"] as? Int,
              let data = try? JSONSerialization.data(withJSONObject: value),
              let layout = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            OpButtonLog.w("Unable to capture panel layout")
            return nil
        }
        self.revision = revision
        self.layout = layout
    }
}
