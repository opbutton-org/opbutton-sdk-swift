import Foundation

public protocol OpButtonLoggerListener: AnyObject {
    func onOpButtonLoggerMessage(_ level: OpButtonLogLevel, tag: String, message: String, error: Error?)
}
