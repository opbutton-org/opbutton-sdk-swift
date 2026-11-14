import Foundation

public protocol OpButtonMetricCollector: AnyObject {
    func collect(_ out: inout [OpButtonMetricEntry])
}
