import Foundation

public enum OpButtonMetricAggregation: String, Sendable {
    case gauge = "gauge"
    case counter = "counter"
    case rate = "rate"
}
