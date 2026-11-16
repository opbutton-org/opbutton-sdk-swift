import Foundation

/// An Objective-C command tab. Close it before releasing the command handlers.
@objcMembers
@objc(OpButtonCommandTab)
public final class OpButtonCommandTab: NSObject {
    private let ui: OpButtonUI
    private let tab: OpButtonTab
    private var layout: OpButtonLayout
    private var callbackIds: [Int] = []
    private var closed = false

    init(ui: OpButtonUI, identifier: String, title: String) {
        let tab = ui.addTab(title).setId(identifier)
        self.ui = ui
        self.tab = tab
        self.layout = tab.horizontal()
        super.init()
    }

    public func addButton(_ identifier: String, title: String, onClick: @escaping () -> Void) {
        guard !closed else { return }
        let button = layout.addButton(title).setId(identifier)
        button.onClick { _ in onClick() }
        callbackIds.append(button.internalId)
    }

    public func setJson(_ description: String, onAction: @escaping (String, Any) -> Void) throws {
        guard !closed else { return }
        let data = Data(description.utf8)
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else { throw OpButtonJsonError.invalidLayout }
        layout = try tab.setJson(json) { identifier, action in
            onAction(identifier, action.payload?["value"] ?? NSNull())
        }
        callbackIds.removeAll()
    }

    public func close() {
        guard !closed else { return }
        closed = true
        for id in callbackIds {
            ui.registerCallback(id, nil)
        }
        callbackIds.removeAll()
        ui.removeTab(tab.id)
    }

    deinit {
        close()
    }
}
