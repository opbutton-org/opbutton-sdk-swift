import Foundation

/// Owns the telemetry outbox and its delivery receipts.
final class OpButtonTelemetry {
    private let logConfig: OpButtonLogConfig
    private let httpClient: OpButtonHttpClient
    private let metrics: OpButtonMetrics
    private var logBuffer: [OpButtonLogEntry] = []
    private var logOverflowWarned = false
    private let logLock = NSLock()

    init(logConfig: OpButtonLogConfig, httpClient: OpButtonHttpClient, metrics: OpButtonMetrics) {
        self.logConfig = logConfig
        self.httpClient = httpClient
        self.metrics = metrics
    }

    func clear() {
        logLock.lock()
        logBuffer.removeAll()
        logLock.unlock()
    }

    func capture() -> Batch {
        let logs = drainLogChunk()
        let samples = metrics.drain()
        return Batch(logs: logs, metrics: samples, commit: { [self] in
            if !logs.isEmpty {
                logLock.lock()
                logOverflowWarned = false
                logLock.unlock()
            }
        }, rollback: { [self] in
            requeueLogs(logs)
            metrics.requeue(samples)
        })
    }

    final class Batch {
        let logs: [OpButtonLogEntry]
        let metrics: [OpButtonMetricEntry]
        private let onCommit: () -> Void
        private let onRollback: () -> Void
        private let lock = NSLock()
        private var settled = false

        init(logs: [OpButtonLogEntry], metrics: [OpButtonMetricEntry], commit: @escaping () -> Void, rollback: @escaping () -> Void) {
            self.logs = logs
            self.metrics = metrics
            onCommit = commit
            onRollback = rollback
        }

        func commit() { settle(onCommit) }
        func rollback() { settle(onRollback) }

        private func settle(_ effect: () -> Void) {
            lock.lock()
            guard !settled else { lock.unlock(); return }
            settled = true
            lock.unlock()
            effect()
        }
    }
    func bufferLog(_ entry: OpButtonLogEntry) {
        logLock.lock()
        defer { logLock.unlock() }

        if logBuffer.count >= logConfig.bufferSize {
            logBuffer.removeFirst()

            if !logOverflowWarned {
                logOverflowWarned = true
                OpButtonLog.w("Log buffer overflow (%d), dropping oldest entries", logConfig.bufferSize)
            }
        }

        logBuffer.append(entry)
    }

    private func drainLogChunk() -> [OpButtonLogEntry] {
        logLock.lock()
        defer { logLock.unlock() }

        guard !logBuffer.isEmpty else { return [] }

        let count = min(logBuffer.count, logConfig.batchSize)
        let chunk = Array(logBuffer.prefix(count))
        logBuffer.removeFirst(count)
        return chunk
    }

    private func requeueLogs(_ chunk: [OpButtonLogEntry]) {
        guard !chunk.isEmpty else { return }

        logLock.lock()
        defer { logLock.unlock() }

        logBuffer.insert(contentsOf: chunk, at: 0)
        while logBuffer.count > logConfig.bufferSize {
            logBuffer.removeLast()
        }
    }

    func flushLogs(sessionToken: String) throws {
        let chunk = drainLogChunk()
        guard !chunk.isEmpty else { return }

        do {
            try httpClient.sendLogs(sessionToken: sessionToken, logs: chunk)
        } catch {
            requeueLogs(chunk)
            throw error
        }
    }

    func flushMetrics(sessionToken: String) throws {
        let chunk = metrics.drain()
        guard !chunk.isEmpty else { return }

        do {
            try httpClient.sendMetrics(sessionToken: sessionToken, metrics: chunk)
        } catch {
            metrics.requeue(chunk)
            throw error
        }
    }

    func resolveLogAttributes() -> [String: Any]? {
        let builder = logConfig.attributes
        let staticAttrs = builder.staticAttributes
        let dynamicAttrs = builder.dynamicAttributes

        guard !staticAttrs.isEmpty || !dynamicAttrs.isEmpty else { return nil }

        var attributes: [String: Any] = staticAttrs

        for (key, provider) in dynamicAttrs {
            attributes[key] = provider() ?? NSNull()
        }

        return attributes.isEmpty ? nil : attributes
    }
}
