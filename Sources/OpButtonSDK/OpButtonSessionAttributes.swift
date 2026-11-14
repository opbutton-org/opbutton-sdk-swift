import Foundation

public final class OpButtonSessionAttributes {
    private(set) var staticAttributes: [String: Any] = [:]
    private(set) var dynamicAttributes: [String: OpButtonValueProvider] = [:]

    public init() {}

    @discardableResult
    public func put(_ key: String, _ value: Any) -> OpButtonSessionAttributes {
        staticAttributes[key] = value
        return self
    }

    @discardableResult
    public func putProvider(_ key: String, _ provider: @escaping OpButtonValueProvider) -> OpButtonSessionAttributes {
        dynamicAttributes[key] = provider
        return self
    }
}
