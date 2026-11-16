import Foundation

/// An Objective-C command tab. Close it before releasing the command handlers.
@objcMembers
@objc(OpButtonCommandTab)
public final class OpButtonCommandTab: NSObject {
    private let ui: OpButtonUI
    private let tab: OpButtonTab
    private let layout: OpButtonLayout
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
