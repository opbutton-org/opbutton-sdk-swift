import Foundation

public final class OpButtonUI {
    private var tabs: [OpButtonTab] = []
    private var callbacks: [Int: OpButtonWidgetCallback] = [:]
    private var providers: Set<ObjectIdentifier> = []
    private var providerWidgets: [OpButtonWidget] = []
    private var idCounter: Int = 0
    private let version: Int = 2
    private var revision: Int = 1
    private var sentRevision: Int = 0
    private let lock = NSLock()

    init() {}

    // MARK: - ID Generation

    func nextId() -> Int {
        lock.lock()
        defer { lock.unlock() }
        idCounter += 1
        return idCounter
    }

    // MARK: - Tab Management

    @discardableResult
    public func addTab(_ title: String) -> OpButtonTab {
        let tab = OpButtonTab(ui: self, title: title)
        lock.lock()
        tabs.removeAll { $0.title == title }
        tabs.append(tab)
        revision += 1
        lock.unlock()
        return tab
    }

    public func getTab(_ id: String) -> OpButtonTab? {
        lock.lock()
        defer { lock.unlock() }
        return tabs.first { $0.id == id }
    }

    public func removeTab(_ id: String) {
        lock.lock()
        tabs.removeAll { $0.id == id }
        revision += 1
        lock.unlock()
    }

    // MARK: - Widget Callbacks

    func registerCallback(_ widgetId: Int, _ callback: OpButtonWidgetCallback?) {
        lock.lock()
        let previousCallback: OpButtonWidgetCallback?
        if let cb = callback {
            previousCallback = callbacks.updateValue(cb, forKey: widgetId)
        } else {
            previousCallback = callbacks.removeValue(forKey: widgetId)
        }
        lock.unlock()
        withExtendedLifetime(previousCallback) {}
    }

    func dispatchAction(_ action: OpButtonAction) -> Bool {
        lock.lock()
        let cb = callbacks[action.widgetId]
        lock.unlock()

        if let cb = cb {
            cb(action)
            return true
        }
        return false
    }

    // MARK: - Value Providers

    func registerProvider(_ widget: OpButtonWidget) {
        lock.lock()
        defer { lock.unlock() }
        let oid = ObjectIdentifier(widget)
        if !providers.contains(oid) {
            providers.insert(oid)
            providerWidgets.append(widget)
        }
    }

    func unregisterProvider(_ widget: OpButtonWidget) {
        lock.lock()
        defer { lock.unlock() }
        let oid = ObjectIdentifier(widget)
        providers.remove(oid)
        providerWidgets.removeAll { ObjectIdentifier($0) == oid }
    }

    func pollValues() {
        lock.lock()
        let widgets = providerWidgets
        lock.unlock()

        for w in widgets {
            if w.pollProvider() {
                lock.lock()
                revision += 1
                lock.unlock()
            }
        }
    }

    // MARK: - Revision Tracking

    func incrementRevision() {
        lock.lock()
        revision += 1
        lock.unlock()
    }

    var hasUnsent: Bool {
        lock.lock()
        defer { lock.unlock() }
        return revision != sentRevision
    }

    func markSent(_ revision: Int) {
        lock.lock()
        sentRevision = max(sentRevision, revision)
        lock.unlock()
    }

    var hasTabs: Bool {
        lock.lock()
        defer { lock.unlock() }
        return !tabs.isEmpty
    }

    public func getRevision() -> Int {
        lock.lock()
        defer { lock.unlock() }
        return revision
    }

    // MARK: - Serialization

    func snapshot() -> OpButtonPanelSnapshot? {
        return OpButtonPanelSnapshot(toJson())
    }

    func toJson() -> [String: Any] {
        lock.lock()
        defer { lock.unlock() }

        return [
            "version": version,
            "revision": revision,
            "tabs": tabs.map { $0.toJson() }
        ]
    }
}
