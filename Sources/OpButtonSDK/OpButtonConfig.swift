import Foundation

public final class OpButtonConfig {
    public let baseUrl: String
    public let apiToken: String
    public let deviceId: String?
    public let deviceName: String?
    public let pollIntervalMs: Int64
    public let actionPollIntervalMs: Int64
    public let autoConnect: Bool
    public weak var loggerListener: OpButtonLoggerListener?
    public weak var sessionListener: OpButtonSessionListener?
    public weak var actionListener: OpButtonActionListener?
    public let sessionAttributes: OpButtonSessionAttributes
    public let logConfig: OpButtonLogConfig
    public let metricConfig: OpButtonMetricConfig
    public let deviceSecret: String?
    public let allowInsecureLocalhost: Bool

    private init(_ builder: Builder) {
        self.baseUrl = builder.baseUrl
        self.apiToken = builder.apiToken
        self.deviceId = builder.deviceId
        self.deviceName = builder.deviceName
        self.pollIntervalMs = builder.pollIntervalMs
        self.actionPollIntervalMs = builder.actionPollIntervalMs
        self.autoConnect = builder.autoConnect
        self.loggerListener = builder.loggerListener
        self.sessionListener = builder.sessionListener
        self.actionListener = builder.actionListener
        self.sessionAttributes = builder.sessionAttributes
        self.logConfig = builder.logConfig
        self.metricConfig = builder.metricConfig
        self.deviceSecret = builder.deviceSecret
        self.allowInsecureLocalhost = builder.allowInsecureLocalhost
    }

    public final class Builder {
        fileprivate var baseUrl: String
        fileprivate var apiToken: String
        fileprivate var deviceId: String?
        fileprivate var deviceName: String?
        fileprivate var pollIntervalMs: Int64 = 10000
        fileprivate var actionPollIntervalMs: Int64 = 2000
        fileprivate var autoConnect: Bool = true
        fileprivate weak var loggerListener: OpButtonLoggerListener?
        fileprivate weak var sessionListener: OpButtonSessionListener?
        fileprivate weak var actionListener: OpButtonActionListener?
        fileprivate var sessionAttributes = OpButtonSessionAttributes()
        fileprivate var logConfig = OpButtonLogConfig()
        fileprivate var metricConfig = OpButtonMetricConfig()
        fileprivate var deviceSecret: String?
        fileprivate var allowInsecureLocalhost = false

        public init(_ baseUrl: String, _ apiToken: String) {
            self.baseUrl = baseUrl.hasSuffix("/") ? String(baseUrl.dropLast()) : baseUrl
            self.apiToken = apiToken
        }

        @discardableResult
        public func setDeviceId(_ deviceId: String) -> Builder {
            self.deviceId = deviceId
            return self
        }

        @discardableResult
        public func setDeviceName(_ deviceName: String) -> Builder {
            self.deviceName = deviceName
            return self
        }

        @discardableResult
        public func setDeviceSecret(_ deviceSecret: String) -> Builder {
            self.deviceSecret = deviceSecret
            return self
        }

        @discardableResult
        public func setAllowInsecureLocalhost(_ allow: Bool) -> Builder {
            self.allowInsecureLocalhost = allow
            return self
        }

        @discardableResult
        public func setPollIntervalMs(_ ms: Int64) -> Builder {
            self.pollIntervalMs = ms
            return self
        }

        @discardableResult
        public func setActionPollIntervalMs(_ ms: Int64) -> Builder {
            self.actionPollIntervalMs = ms
            return self
        }

        @discardableResult
        public func setAutoConnect(_ autoConnect: Bool) -> Builder {
            self.autoConnect = autoConnect
            return self
        }

        @discardableResult
        public func setLoggerListener(_ listener: OpButtonLoggerListener?) -> Builder {
            self.loggerListener = listener
            return self
        }

        @discardableResult
        public func setSessionListener(_ listener: OpButtonSessionListener?) -> Builder {
            self.sessionListener = listener
            return self
        }

        @discardableResult
        public func setActionListener(_ listener: OpButtonActionListener?) -> Builder {
            self.actionListener = listener
            return self
        }

        @discardableResult
        public func setSessionAttributes(_ attributes: OpButtonSessionAttributes) -> Builder {
            self.sessionAttributes = attributes
            return self
        }

        @discardableResult
        public func setLogConfig(_ config: OpButtonLogConfig) -> Builder {
            self.logConfig = config
            return self
        }

        @discardableResult
        public func setMetricConfig(_ config: OpButtonMetricConfig) -> Builder {
            self.metricConfig = config
            return self
        }

        public func build() -> OpButtonConfig {
            precondition(!baseUrl.isEmpty, "baseUrl is required")
            precondition(!apiToken.isEmpty && Self.isSafeHeaderValue(apiToken),
                         "apiToken is required and must contain only printable ASCII characters")
            precondition((250...300000).contains(pollIntervalMs)
                && (250...300000).contains(actionPollIntervalMs),
                "poll intervals must be between 250ms and 300000ms")
            precondition(deviceSecret == nil || ((32...256).contains(deviceSecret!.count)
                && Self.isSafeHeaderValue(deviceSecret!)),
                "deviceSecret must contain 32 to 256 printable ASCII characters")
            guard let components = URLComponents(string: baseUrl),
                  let scheme = components.scheme?.lowercased(),
                  let host = components.host?.lowercased(),
                  components.user == nil, components.password == nil,
                  components.query == nil, components.fragment == nil else {
                preconditionFailure("baseUrl is invalid or contains credentials")
            }
            let local = host == "localhost" || host == "127.0.0.1" || host == "::1"
                || host == "[::1]"
            precondition(scheme == "https" || (allowInsecureLocalhost && scheme == "http" && local),
                         "baseUrl must use HTTPS; localhost HTTP requires setAllowInsecureLocalhost(true)")
            return OpButtonConfig(self)
        }

        private static func isSafeHeaderValue(_ value: String) -> Bool {
            !value.unicodeScalars.isEmpty && value.unicodeScalars.allSatisfy {
                (0x21...0x7e).contains($0.value)
            }
        }
    }
}
