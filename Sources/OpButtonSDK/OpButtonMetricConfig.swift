import Foundation

public final class OpButtonMetricConfig {
    private(set) var enabled: Bool = true
    private(set) var sampleIntervalMs: Int64 = 200
    private(set) var bufferSize: Int = 2000
    private(set) var batchSize: Int = 200
    private(set) var collectors: [OpButtonMetricCollector] = []

    public init() {}

    @discardableResult
    public func setEnabled(_ enabled: Bool) -> OpButtonMetricConfig {
        self.enabled = enabled
        return self
    }

    @discardableResult
    public func setSampleIntervalMs(_ ms: Int64) -> OpButtonMetricConfig {
        self.sampleIntervalMs = max(100, min(1000, ms))
        return self
    }

    @discardableResult
    public func setBufferSize(_ size: Int) -> OpButtonMetricConfig {
        self.bufferSize = size
        return self
    }

    @discardableResult
    public func setBatchSize(_ size: Int) -> OpButtonMetricConfig {
        self.batchSize = size
        return self
    }

    @discardableResult
    public func addCollector(_ collector: OpButtonMetricCollector) -> OpButtonMetricConfig {
        self.collectors.append(collector)
        return self
    }
}
