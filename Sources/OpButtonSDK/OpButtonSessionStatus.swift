import Foundation

public enum OpButtonSessionStatus: String, Sendable {
    case disconnected
    case connecting
    case waitingApproval
    case active
    case authFailed
    case rejected
    case closed
    case error
}
