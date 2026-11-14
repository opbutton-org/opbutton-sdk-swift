import Foundation

public final class OpButtonLogConfig {
    private(set) var enabled: Bool = true
    private(set) var logLevel: OpButtonLogLevel = .info
    private(set) var batchSize: Int = 100
    private(set) var bufferSize: Int = 1000
    private(set) var attributes: OpButtonLogAttributes = OpButtonLogAttributes()

    public init() {}

    @discardableResult
    public func setEnabled(_ enabled: Bool) -> OpButtonLogConfig {
        self.enabled = enabled
        return self
    }

    @discardableResult
    public func setLogLevel(_ level: OpButtonLogLevel) -> OpButtonLogConfig {
        self.logLevel = level
        return self
    }

    @discardableResult
    public func setBatchSize(_ size: Int) -> OpButtonLogConfig {
        self.batchSize = size
        return self
    }

    @discardableResult
    public func setBufferSize(_ size: Int) -> OpButtonLogConfig {
        self.bufferSize = size
        return self
    }

    @discardableResult
    public func setAttributes(_ attributes: OpButtonLogAttributes) -> OpButtonLogConfig {
        self.attributes = attributes
        return self
    }
}
