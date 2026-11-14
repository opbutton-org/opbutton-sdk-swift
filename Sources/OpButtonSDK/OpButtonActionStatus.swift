import Foundation

public enum OpButtonActionStatus: String, Sendable {
    case pending = "pending"
    case delivered = "delivered"
    case acknowledged = "acknowledged"
    case unknown = ""

    public static func from(_ value: String) -> OpButtonActionStatus {
        return OpButtonActionStatus(rawValue: value) ?? .unknown
    }
}
