import Foundation
import os.log

final class OpButtonLog {
    static let tag = "OpButtonSDK"
    private static var level: OpButtonLogLevel = .info
    private static weak var loggerListener: OpButtonLoggerListener?

    static func setLevel(_ level: OpButtonLogLevel) {
        self.level = level
    }

    static func setLoggerListener(_ listener: OpButtonLoggerListener?) {
        self.loggerListener = listener
    }

    static func d(_ message: String, _ args: CVarArg...) {
        guard level <= .debug else { return }
        let msg = args.isEmpty ? message : String(format: message, arguments: args)
        if let listener = loggerListener {
            listener.onOpButtonLoggerMessage(.debug, tag: tag, message: msg, error: nil)
        } else {
            os_log(.debug, "%{public}@: %{public}@", tag, msg)
        }
    }

    static func i(_ message: String, _ args: CVarArg...) {
        guard level <= .info else { return }
        let msg = args.isEmpty ? message : String(format: message, arguments: args)
        if let listener = loggerListener {
            listener.onOpButtonLoggerMessage(.info, tag: tag, message: msg, error: nil)
        } else {
            os_log(.info, "%{public}@: %{public}@", tag, msg)
        }
    }

    static func w(_ message: String, _ args: CVarArg...) {
        guard level <= .warning else { return }
        let msg = args.isEmpty ? message : String(format: message, arguments: args)
        if let listener = loggerListener {
            listener.onOpButtonLoggerMessage(.warning, tag: tag, message: msg, error: nil)
        } else {
            os_log(.default, "%{public}@: %{public}@", tag, msg)
        }
    }

    static func e(_ message: String, _ args: CVarArg...) {
        guard level <= .error else { return }
        let msg = args.isEmpty ? message : String(format: message, arguments: args)
        if let listener = loggerListener {
            listener.onOpButtonLoggerMessage(.error, tag: tag, message: msg, error: nil)
        } else {
            os_log(.error, "%{public}@: %{public}@", tag, msg)
        }
    }

    static func e(_ message: String, _ error: Error) {
        if let listener = loggerListener {
            listener.onOpButtonLoggerMessage(.exception, tag: tag, message: message, error: error)
        } else {
            os_log(.error, "%{public}@: %{public}@ — %{public}@", tag, message, error.localizedDescription)
        }
    }
}
