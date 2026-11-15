import Foundation

/// The single execution boundary for host UI providers and panel snapshots.
enum OpButtonMainThread {
    static func sync<T>(_ operation: () -> T) -> T {
        if Thread.isMainThread { return operation() }
        return DispatchQueue.main.sync(execute: operation)
    }
}
