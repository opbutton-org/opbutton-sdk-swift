import Foundation

public final class OpButtonMetricType: Hashable, Sendable {
    public let key: String
    public let unit: String
    public let aggregation: OpButtonMetricAggregation

    // Built-in metric types
    public static let fps = OpButtonMetricType(key: "fps", unit: "", aggregation: .gauge)
    public static let frameTime = OpButtonMetricType(key: "frame_time", unit: "ms", aggregation: .gauge)
    public static let memory = OpButtonMetricType(key: "memory", unit: "bytes", aggregation: .gauge)
    public static let videoMemory = OpButtonMetricType(key: "video_memory", unit: "bytes", aggregation: .gauge)
    public static let cpuUsage = OpButtonMetricType(key: "cpu_usage", unit: "%", aggregation: .gauge)
    public static let networkRx = OpButtonMetricType(key: "network_rx", unit: "bytes/s", aggregation: .rate)
    public static let networkTx = OpButtonMetricType(key: "network_tx", unit: "bytes/s", aggregation: .rate)
    public static let batteryLevel = OpButtonMetricType(key: "battery_level", unit: "%", aggregation: .gauge)
    public static let batteryCharging = OpButtonMetricType(key: "battery_charging", unit: "", aggregation: .gauge)
    public static let drawCalls = OpButtonMetricType(key: "draw_calls", unit: "", aggregation: .gauge)
    public static let threadCount = OpButtonMetricType(key: "thread_count", unit: "", aggregation: .gauge)

    private init(key: String, unit: String, aggregation: OpButtonMetricAggregation) {
        self.key = key
        self.unit = unit
        self.aggregation = aggregation
    }

    public static func create(_ key: String) -> OpButtonMetricType {
        return OpButtonMetricType(key: key, unit: "", aggregation: .gauge)
    }

    public static func create(_ key: String, unit: String) -> OpButtonMetricType {
        return OpButtonMetricType(key: key, unit: unit, aggregation: .gauge)
    }

    public static func create(_ key: String, unit: String, aggregation: OpButtonMetricAggregation) -> OpButtonMetricType {
        return OpButtonMetricType(key: key, unit: unit, aggregation: aggregation)
    }

    public static func == (lhs: OpButtonMetricType, rhs: OpButtonMetricType) -> Bool {
        return lhs.key == rhs.key
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(key)
    }
}
