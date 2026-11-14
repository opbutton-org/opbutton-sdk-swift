import Foundation

public final class OpButtonLogAttributes {
    private(set) var staticAttributes: [String: Any] = [:]
    private(set) var dynamicAttributes: [String: OpButtonValueProvider] = [:]

    public init() {}

    @discardableResult
    public func put(_ key: String, _ value: Any) -> OpButtonLogAttributes {
        staticAttributes[key] = value
        return self
    }

    @discardableResult
    public func putProvider(_ key: String, _ provider: @escaping OpButtonValueProvider) -> OpButtonLogAttributes {
        dynamicAttributes[key] = provider
        return self
    }
}
