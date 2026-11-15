import Foundation
#if canImport(UIKit)
import UIKit
#endif

public final class OpButton {
    public static let version = "1.0.61"

    private static var instance: OpButtonRuntime?
    private static let instanceLock = NSLock()

    private init() {}

    // MARK: - Static API

    public static func initialize(_ config: OpButtonConfig) {
        initialize(config, httpClient: nil)
    }

    static func initialize(_ config: OpButtonConfig, httpClient: OpButtonHttpClient?) {
        instanceLock.lock()
        defer { instanceLock.unlock() }

        guard instance == nil else {
            OpButtonLog.w("OpButton.initialize() called more than once, ignoring")
            return
        }

        let p = OpButtonRuntime(config: config, httpClient: httpClient)
        instance = p
        OpButtonLog.i("OpButton SDK initialized (server: %@)", config.baseUrl)
        p.logConfiguration()

        if config.autoConnect {
            p.startConnection()
        }
    }

    public static var isInitialized: Bool {
        instanceLock.lock()
        defer { instanceLock.unlock() }
        return instance != nil
    }

    public static func getStatus() -> OpButtonSessionStatus {
        return instance?.currentStatus() ?? .disconnected
    }

    public static func addActionListener(_ listener: OpButtonActionListener) {
        requireInstance().addActionListener(listener)
    }

    public static func removeActionListener(_ listener: OpButtonActionListener) {
        instance?.removeActionListener(listener)
    }

    public static func addSessionListener(_ listener: OpButtonSessionListener) {
        requireInstance().addSessionListener(listener)
    }

    public static func removeSessionListener(_ listener: OpButtonSessionListener) {
        instance?.removeSessionListener(listener)
    }

    public static func getUI() -> OpButtonUI {
        return requireInstance().ui
    }

    public static func getMetrics() -> OpButtonMetrics {
        return requireInstance().metrics
    }

    public static func connect() {
        requireInstance().startConnection()
    }

    public static func disconnect() {
        instance?.stopConnection()
    }

    // MARK: - Logging

    public static func log(_ level: OpButtonLogLevel, _ message: String) {
        guard let p = instance, p.isLoggingEnabled else { return }
        p.telemetry.bufferLog(OpButtonLogEntry(level: level, message: message,
                                   category: nil, thread: nil,
                                   metadata: nil, attributes: p.telemetry.resolveLogAttributes()))
    }

    public static func log(_ level: OpButtonLogLevel, _ message: String,
                           category: String?, thread: String?) {
        guard let p = instance, p.isLoggingEnabled else { return }
        p.telemetry.bufferLog(OpButtonLogEntry(level: level, message: message,
                                   category: category, thread: thread,
                                   metadata: nil, attributes: p.telemetry.resolveLogAttributes()))
    }

    public static func log(_ level: OpButtonLogLevel, _ message: String,
                           metadata: [String: Any]?) {
        guard let p = instance, p.isLoggingEnabled else { return }
        p.telemetry.bufferLog(OpButtonLogEntry(level: level, message: message,
                                   category: nil, thread: nil,
                                   metadata: metadata, attributes: p.telemetry.resolveLogAttributes()))
    }

    public static func log(_ level: OpButtonLogLevel, _ message: String,
                           category: String?, thread: String?,
                           metadata: [String: Any]?) {
        guard let p = instance, p.isLoggingEnabled else { return }
        p.telemetry.bufferLog(OpButtonLogEntry(level: level, message: message,
                                   category: category, thread: thread,
                                   metadata: metadata, attributes: p.telemetry.resolveLogAttributes()))
    }

    public static func log(_ entry: OpButtonLogEntry) {
        guard let p = instance, p.isLoggingEnabled else { return }
        p.telemetry.bufferLog(entry)
    }

    // MARK: - Events

    public static func event(_ message: String) {
        event(message, category: nil, metadata: nil)
    }

    public static func event(_ message: String, metadata: [String: Any]?) {
        event(message, category: nil, metadata: metadata)
    }

    public static func event(_ message: String, category: String?,
                             metadata: [String: Any]?) {
        bufferStructuredLog(kind: "event", message: message,
                            category: category, metadata: metadata,
                            clientTimestamp: Date())
    }

    public static func event(_ message: String, category: String?,
                             metadata: [String: Any]?, clientTimestamp: Date) {
        bufferStructuredLog(kind: "event", message: message,
                            category: category, metadata: metadata,
                            clientTimestamp: clientTimestamp)
    }

    // MARK: - Revenue

    public static func revenue(_ message: String) {
        revenue(message, category: nil, metadata: nil)
    }

    public static func revenue(_ message: String, metadata: [String: Any]?) {
        revenue(message, category: nil, metadata: metadata)
    }

    public static func revenue(_ message: String, category: String?,
                               metadata: [String: Any]?) {
        bufferStructuredLog(kind: "revenue", message: message,
                            category: category, metadata: metadata,
                            clientTimestamp: Date())
    }

    // MARK: - Screen Tracking

    public static func changeScreen(screenType: String, screenName: String) {
        let metadata: [String: Any] = [
            "opbutton_command": "change_screen",
            "opbutton_slice_type": "screen",
            "opbutton_slice_name": screenName,
            "screen_type": screenType,
            "screen_name": screenName
        ]

        event("change_screen", category: "change_screen", metadata: metadata)
    }

    // MARK: - In-App Products

    public static func setInAppProducts(_ products: [[String: Any]]) {
        let metadata: [String: Any] = [
            "opbutton_command": "set_in_app_products",
            "opbutton_purchase_entry_type": "catalog",
            "in_app_products": products,
            "in_app_product_count": products.count
        ]

        bufferStructuredLog(kind: "purchase", message: "set_in_app_products",
                            category: "catalog", metadata: metadata,
                            clientTimestamp: Date())
    }

    public static func setOwnedInAppProducts(_ productIds: [String]) {
        let metadata: [String: Any] = [
            "opbutton_command": "set_owned_in_app_products",
            "opbutton_purchase_entry_type": "owned",
            "owned_in_app_products": productIds,
            "owned_in_app_product_count": productIds.count
        ]

        bufferStructuredLog(kind: "purchase", message: "set_owned_in_app_products",
                            category: "owned", metadata: metadata,
                            clientTimestamp: Date())
    }

    public static func purchaseInApp(transactionId: String?,
                                     productIds: [String],
                                     metadata: [String: Any]? = nil) {
        var purchaseMetadata: [String: Any] = metadata ?? [:]
        purchaseMetadata["opbutton_command"] = "purchase_in_app"
        purchaseMetadata["opbutton_purchase_entry_type"] = "purchase"
        purchaseMetadata["in_app_products"] = productIds
        purchaseMetadata["in_app_product_count"] = productIds.count

        if let transactionId = transactionId, !transactionId.isEmpty {
            purchaseMetadata["transaction_id"] = transactionId
        }

        let message = productIds.isEmpty ? "purchase_in_app" : productIds[0]

        bufferStructuredLog(kind: "purchase", message: message,
                            category: "purchase", metadata: purchaseMetadata,
                            clientTimestamp: Date())
    }

    // MARK: - Acknowledge

    public static func acknowledgeAction(_ actionId: String, _ ackPayload: [String: Any]? = nil) {
        instance?.acknowledgeAction(actionId, ackPayload)
    }

    // MARK: - Shutdown

    public static func shutdown() {
        instanceLock.lock()
        let p = instance
        instance = nil
        instanceLock.unlock()

        p?.doShutdown()
    }

    // MARK: - Internal

    private static func requireInstance() -> OpButtonRuntime {
        guard let p = instance else {
            fatalError("OpButton.initialize() must be called first")
        }
        return p
    }

    private static func bufferStructuredLog(kind: String, message: String,
                                            category: String?, metadata: [String: Any]?,
                                            clientTimestamp: Date) {
        guard let p = instance, p.isLoggingEnabled else { return }

        let resolvedCategory = resolveStructuredCategory(kind: kind, category: category)
        var merged = metadata ?? [:]
        merged["opbutton_kind"] = kind

        p.telemetry.bufferLog(OpButtonLogEntry(
            level: .info, message: message,
            category: resolvedCategory, thread: nil,
            metadata: merged, attributes: p.telemetry.resolveLogAttributes(),
            clientTimestamp: clientTimestamp
        ))
    }

    private static func resolveStructuredCategory(kind: String, category: String?) -> String {
        guard let category = category, !category.isEmpty else { return kind }
        if category == kind || category.hasPrefix(kind + "_") { return category }
        return kind + "_" + category
    }

}
