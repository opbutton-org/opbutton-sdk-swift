import Foundation

public final class OpButtonMetrics {
    private var collectors: [OpButtonMetricCollector] = []
    private var buffer: [OpButtonMetricEntry] = []
    private let lock = NSLock()
    private let collectorsLock = NSLock()

    private(set) var sampleIntervalMs: Int64 = 200
    private var bufferSize: Int = 2000
    private(set) var batchSize: Int = 200

    init() {}

    public func setSampleIntervalMs(_ intervalMs: Int64) {
        sampleIntervalMs = max(100, min(1000, intervalMs))
    }

    public func setBufferSize(_ size: Int) {
        bufferSize = size
    }

    public func setBatchSize(_ size: Int) {
        batchSize = size
    }

    public func addCollector(_ collector: OpButtonMetricCollector) {
        collectorsLock.lock()
        collectors.append(collector)
        collectorsLock.unlock()
    }

    public func removeCollector(_ collector: OpButtonMetricCollector) {
        collectorsLock.lock()
        collectors.removeAll { $0 === collector }
        collectorsLock.unlock()
    }

    public func record(_ metricType: OpButtonMetricType, _ value: Double) {
        bufferEntry(OpButtonMetricEntry(metricType, value))
    }

    public func record(_ metricType: OpButtonMetricType, _ value: Double, timestampMs: Int64) {
        bufferEntry(OpButtonMetricEntry(metricType, value, timestampMs: timestampMs))
    }

    func sample() {
        var collected: [OpButtonMetricEntry] = []

        collectorsLock.lock()
        let currentCollectors = collectors
        collectorsLock.unlock()

        for collector in currentCollectors {
            collector.collect(&collected)
        }

        for entry in collected {
            bufferEntry(entry)
        }
    }

    func drain() -> [OpButtonMetricEntry] {
        lock.lock()
        defer { lock.unlock() }

        guard !buffer.isEmpty else { return [] }

        let count = min(buffer.count, batchSize)
        let chunk = Array(buffer.prefix(count))
        buffer.removeFirst(count)
        return chunk
    }

    func requeue(_ entries: [OpButtonMetricEntry]) {
        lock.lock()
        defer { lock.unlock() }

        buffer.insert(contentsOf: entries, at: 0)
        while buffer.count > bufferSize {
            buffer.removeLast()
        }
    }

    var hasData: Bool {
        lock.lock()
        defer { lock.unlock() }
        return !buffer.isEmpty
    }

    func clear() {
        lock.lock()
        buffer.removeAll()
        lock.unlock()

        collectorsLock.lock()
        collectors.removeAll()
        collectorsLock.unlock()
    }

    private func bufferEntry(_ entry: OpButtonMetricEntry) {
        lock.lock()
        defer { lock.unlock() }

        if buffer.count >= bufferSize {
            buffer.removeFirst()
        }
        buffer.append(entry)
    }
}
