import Foundation

// MARK: - ObjC-compatible enums

@objc(OpButtonObjCLogLevel)
public enum OpButtonObjCLogLevel: Int {
    case debug = 0
    case info = 1
    case warning = 2
    case error = 3
    case critical = 4
    case exception = 5

    var swift: OpButtonLogLevel {
        switch self {
        case .debug: return .debug
        case .info: return .info
        case .warning: return .warning
        case .error: return .error
        case .critical: return .critical
        case .exception: return .exception
        }
    }

    static func from(_ swift: OpButtonLogLevel) -> OpButtonObjCLogLevel {
        switch swift {
        case .debug: return .debug
        case .info: return .info
        case .warning: return .warning
        case .error: return .error
        case .critical: return .critical
        case .exception: return .exception
        }
    }
}

@objc(OpButtonObjCSessionStatus)
public enum OpButtonObjCSessionStatus: Int {
    case disconnected = 0
    case connecting = 1
    case waitingApproval = 2
    case active = 3
    case authFailed = 4
    case rejected = 5
    case closed = 6
    case error = 7
}

// MARK: - ObjC-compatible protocols

@objc(OpButtonObjCSessionDelegate)
public protocol OpButtonObjCSessionDelegate {
    @objc func onOpButtonSessionConnecting()
    @objc func onOpButtonSessionWaitingApproval(_ requestId: String)
    @objc func onOpButtonSessionStarted(_ sessionToken: String)
    @objc func onOpButtonSessionClosed()
    @objc func onOpButtonSessionRejected()
    @objc func onOpButtonSessionAuthFailed()
    @objc func onOpButtonSessionError(_ message: String)
}

@objc(OpButtonObjCActionDelegate)
public protocol OpButtonObjCActionDelegate {
    @objc func onOpButtonActionReceived(_ actionId: String, widgetId: Int, actionType: String)
}

@objc(OpButtonObjCLoggerDelegate)
public protocol OpButtonObjCLoggerDelegate {
    @objc func onOpButtonLoggerMessage(_ level: OpButtonObjCLogLevel, tag: String, message: String)
}

// MARK: - Internal adapters

private class SessionDelegateAdapter: OpButtonSessionListener {
    weak var delegate: OpButtonObjCSessionDelegate?

    init(_ delegate: OpButtonObjCSessionDelegate) {
        self.delegate = delegate
    }

    func onOpButtonSessionConnecting() {
        delegate?.onOpButtonSessionConnecting()
    }

    func onOpButtonSessionWaitingApproval(_ requestId: String) {
        delegate?.onOpButtonSessionWaitingApproval(requestId)
    }

    func onOpButtonSessionStarted(_ sessionToken: String) {
        delegate?.onOpButtonSessionStarted(sessionToken)
    }

    func onOpButtonSessionClosed() {
        delegate?.onOpButtonSessionClosed()
    }

    func onOpButtonSessionRejected() {
        delegate?.onOpButtonSessionRejected()
    }

    func onOpButtonSessionAuthFailed() {
        delegate?.onOpButtonSessionAuthFailed()
    }

    func onOpButtonSessionError(_ error: OpButtonError) {
        delegate?.onOpButtonSessionError(error.message)
    }
}

private class ActionDelegateAdapter: OpButtonActionListener {
    weak var delegate: OpButtonObjCActionDelegate?

    init(_ delegate: OpButtonObjCActionDelegate) {
        self.delegate = delegate
    }

    func onOpButtonActionReceived(_ action: OpButtonAction) {
        delegate?.onOpButtonActionReceived(action.id, widgetId: action.widgetId, actionType: action.actionType.rawValue)
    }
}

private class LoggerDelegateAdapter: OpButtonLoggerListener {
    weak var delegate: OpButtonObjCLoggerDelegate?

    init(_ delegate: OpButtonObjCLoggerDelegate) {
        self.delegate = delegate
    }

    func onOpButtonLoggerMessage(_ level: OpButtonLogLevel, tag: String, message: String, error: Error?) {
        delegate?.onOpButtonLoggerMessage(OpButtonObjCLogLevel.from(level), tag: tag, message: message)
    }
}

// MARK: - ObjC-compatible config builders

@objcMembers
@objc(OpButtonSessionAttributeBuilder)
public class OpButtonObjCSessionAttributeBuilder: NSObject {
    fileprivate let attrs = OpButtonSessionAttributes()

    @discardableResult
    public func put(_ key: String, value: Any) -> OpButtonObjCSessionAttributeBuilder {
        attrs.put(key, value)
        return self
    }

    @discardableResult
    public func putProvider(_ key: String, provider: @escaping () -> Any?) -> OpButtonObjCSessionAttributeBuilder {
        attrs.putProvider(key, provider)
        return self
    }
}

@objcMembers
@objc(OpButtonLogAttributeBuilder)
public class OpButtonObjCLogAttributeBuilder: NSObject {
    fileprivate let attrs = OpButtonLogAttributes()

    @discardableResult
    public func put(_ key: String, value: Any) -> OpButtonObjCLogAttributeBuilder {
        attrs.put(key, value)
        return self
    }

    @discardableResult
    public func putProvider(_ key: String, provider: @escaping () -> Any?) -> OpButtonObjCLogAttributeBuilder {
        attrs.putProvider(key, provider)
        return self
    }
}

@objcMembers
@objc(OpButtonLogConfigBuilder)
public class OpButtonObjCLogConfigBuilder: NSObject {
    fileprivate let config = OpButtonLogConfig()

    @discardableResult
    public func setEnabled(_ enabled: Bool) -> OpButtonObjCLogConfigBuilder {
        config.setEnabled(enabled)
        return self
    }

    @discardableResult
    public func setLogLevel(_ level: OpButtonObjCLogLevel) -> OpButtonObjCLogConfigBuilder {
        config.setLogLevel(level.swift)
        return self
    }

    @discardableResult
    public func setAttributes(_ attributes: OpButtonObjCLogAttributeBuilder) -> OpButtonObjCLogConfigBuilder {
        config.setAttributes(attributes.attrs)
        return self
    }
}

@objcMembers
@objc(OpButtonMetricConfigBuilder)
public class OpButtonObjCMetricConfigBuilder: NSObject {
    fileprivate let config = OpButtonMetricConfig()

    @discardableResult
    public func setEnabled(_ enabled: Bool) -> OpButtonObjCMetricConfigBuilder {
        config.setEnabled(enabled)
        return self
    }

    @discardableResult
    public func setSampleIntervalMs(_ ms: Int) -> OpButtonObjCMetricConfigBuilder {
        config.setSampleIntervalMs(Int64(ms))
        return self
    }
}

@objcMembers
@objc(OpButtonConfigBuilder)
public class OpButtonObjCConfigBuilder: NSObject {
    fileprivate let builder: OpButtonConfig.Builder

    public init(apiUrl: String, apiToken: String) {
        self.builder = OpButtonConfig.Builder(apiUrl, apiToken)
        super.init()
    }

    @discardableResult
    public func setLoggerListener(_ listener: OpButtonObjCLoggerDelegate) -> OpButtonObjCConfigBuilder {
        let adapter = LoggerDelegateAdapter(listener)
        OpButtonBridge.loggerAdapter = adapter
        builder.setLoggerListener(adapter)
        return self
    }

    @discardableResult
    public func setSessionListener(_ listener: OpButtonObjCSessionDelegate) -> OpButtonObjCConfigBuilder {
        let adapter = SessionDelegateAdapter(listener)
        OpButtonBridge.sessionAdapter = adapter
        builder.setSessionListener(adapter)
        return self
    }

    @discardableResult
    public func setActionListener(_ listener: OpButtonObjCActionDelegate) -> OpButtonObjCConfigBuilder {
        let adapter = ActionDelegateAdapter(listener)
        OpButtonBridge.actionAdapter = adapter
        builder.setActionListener(adapter)
        return self
    }

    @discardableResult
    public func setSessionAttributes(_ attributes: OpButtonObjCSessionAttributeBuilder) -> OpButtonObjCConfigBuilder {
        builder.setSessionAttributes(attributes.attrs)
        return self
    }

    @discardableResult
    public func setLogConfig(_ logConfig: OpButtonObjCLogConfigBuilder) -> OpButtonObjCConfigBuilder {
        builder.setLogConfig(logConfig.config)
        return self
    }

    @discardableResult
    public func setMetricConfig(_ metricConfig: OpButtonObjCMetricConfigBuilder) -> OpButtonObjCConfigBuilder {
        builder.setMetricConfig(metricConfig.config)
        return self
    }

    public func build() -> OpButtonConfig {
        return builder.build()
    }
}

// MARK: - Main Bridge

@objcMembers
@objc(OpButtonBridge)
public class OpButtonBridge: NSObject {
    fileprivate static var sessionAdapter: SessionDelegateAdapter?
    fileprivate static var actionAdapter: ActionDelegateAdapter?
    fileprivate static var loggerAdapter: LoggerDelegateAdapter?

    public static let sdkVersion: String = OpButton.version

    public static func isInitialized() -> Bool {
        return OpButton.isInitialized
    }

    public static func createCommandTab(_ identifier: String, title: String) -> OpButtonCommandTab? {
        guard OpButton.isInitialized else { return nil }
        return OpButtonCommandTab(ui: OpButton.getUI(), identifier: identifier, title: title)
    }

    public static func initialize(_ config: OpButtonConfig) {
        OpButton.initialize(config)
    }

    @objc(initialize:)
    public static func initialize(_ builder: OpButtonObjCConfigBuilder) {
        OpButton.initialize(builder.build())
    }

    public static func sendLog(_ level: OpButtonObjCLogLevel, message: String) {
        OpButton.log(level.swift, message)
    }

    public static func sendLogDetailed(_ level: OpButtonObjCLogLevel, message: String,
                                       category: String?, thread: String?) {
        OpButton.log(level.swift, message, category: category, thread: thread)
    }

    public static func sendEvent(_ message: String, metadata: NSDictionary?) {
        OpButton.event(message, metadata: metadata as? [String: Any])
    }

    public static func sendRevenue(_ message: String, metadata: NSDictionary?) {
        OpButton.revenue(message, metadata: metadata as? [String: Any])
    }

    public static func changeScreen(type: String, name: String) {
        OpButton.changeScreen(screenType: type, screenName: name)
    }

    public static func setInAppProducts(_ products: NSArray) {
        let swiftProducts = products as? [[String: Any]] ?? []
        OpButton.setInAppProducts(swiftProducts)
    }

    public static func setOwnedInAppProducts(_ productIds: [String]) {
        OpButton.setOwnedInAppProducts(productIds)
    }

    public static func purchaseInApp(_ transactionId: String?,
                                     productIds: [String],
                                     metadata: NSDictionary?) {
        OpButton.purchaseInApp(transactionId: transactionId,
                            productIds: productIds,
                            metadata: metadata as? [String: Any])
    }

    public static func acknowledgeAction(_ actionId: String, payload: NSDictionary?) {
        OpButton.acknowledgeAction(actionId, payload as? [String: Any])
    }

    public static func shutdown() {
        OpButton.shutdown()
        sessionAdapter = nil
        actionAdapter = nil
        loggerAdapter = nil
    }

    public static func getStatus() -> OpButtonObjCSessionStatus {
        let status = OpButton.getStatus()
        switch status {
        case .disconnected: return .disconnected
        case .connecting: return .connecting
        case .waitingApproval: return .waitingApproval
        case .active: return .active
        case .authFailed: return .authFailed
        case .rejected: return .rejected
        case .closed: return .closed
        case .error: return .error
        }
    }
}
