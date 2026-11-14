import XCTest
@testable import OpButtonSDK

final class CommandTabTests: XCTestCase {
    private final class HandlerOwner {
        var calls = 0
    }

    private final class WeakOwner {
        weak var value: HandlerOwner?

        init(_ value: HandlerOwner?) {
            self.value = value
        }
    }

    func testCommandDispatchAndCloseReleaseHandlers() throws {
        let ui = OpButtonUI()
        let tab = OpButtonCommandTab(ui: ui, identifier: "game", title: "Game")
        var owner: HandlerOwner? = HandlerOwner()
        let releasedOwner = WeakOwner(owner)
        tab.addButton("start", title: "Start") { [owner = owner!] in owner.calls += 1 }
        owner = nil

        let tabs = try XCTUnwrap(ui.toJson()["tabs"] as? [[String: Any]])
        let layout = try XCTUnwrap(tabs.first?["layout"] as? [String: Any])
        let children = try XCTUnwrap(layout["children"] as? [[String: Any]])
        let id = try XCTUnwrap(children.first?["id"] as? Int)
        let action = OpButtonAction(id: "command", sessionId: "session", widgetId: id,
                                    actionType: .click, status: .pending, payload: nil)

        XCTAssertTrue(ui.dispatchAction(action))
        XCTAssertEqual(releasedOwner.value?.calls, 1)
        tab.close()
        XCTAssertFalse(ui.hasTabs)
        XCTAssertFalse(ui.dispatchAction(action))
        XCTAssertNil(releasedOwner.value)
        tab.close()
        tab.addButton("late", title: "Late") { XCTFail("Closed tab accepted a handler") }
        XCTAssertFalse(ui.hasTabs)
    }

    func testObjectiveCSelectorsMatchNativeHost() {
        let ui = OpButtonUI()
        let tab = OpButtonCommandTab(ui: ui, identifier: "game", title: "Game")
        XCTAssertTrue(tab.responds(to: NSSelectorFromString("addButton:title:onClick:")))
        XCTAssertTrue(tab.responds(to: NSSelectorFromString("close")))
        XCTAssertTrue(OpButtonBridge.responds(to: NSSelectorFromString("createCommandTab:title:")))
        XCTAssertTrue(OpButtonBridge.responds(to: NSSelectorFromString("isInitialized")))
        tab.close()
    }
}
