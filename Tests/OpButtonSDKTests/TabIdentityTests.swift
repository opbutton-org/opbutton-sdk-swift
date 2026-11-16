import XCTest
@testable import OpButtonSDK

final class TabIdentityTests: XCTestCase {
    func testNamesDoNotChangeIdentityOrCallbacks() throws {
        let ui = OpButtonUI()
        let tab = ui.getOrCreateTab("controls")
        XCTAssertEqual(tab.id, "controls")
        XCTAssertEqual(tab.title, "controls")
        var calls = 0
        let button = tab.vertical().addButton("Run")
        button.onClick { _ in calls += 1 }
        let action = OpButtonAction.fromJson(["widget_id": button.internalId])
        let revision = ui.getRevision()

        tab.setName("Game controls")
        XCTAssertGreaterThan(ui.getRevision(), revision)
        let renamedRevision = ui.getRevision()
        XCTAssertTrue(ui.getOrCreateTab("controls") === tab)
        XCTAssertEqual(ui.getRevision(), renamedRevision)
        XCTAssertEqual(tab.toJson()["title"] as? String, "Game controls")
        XCTAssertTrue(ui.dispatchAction(action))
        XCTAssertEqual(calls, 1)

        ui.getOrCreateTab("other").setName("Game controls")
        XCTAssertEqual((ui.toJson()["tabs"] as? [[String: Any]])?.count, 2)
        ui.addTab("controls")
        XCTAssertEqual((ui.toJson()["tabs"] as? [[String: Any]])?.count, 2)
        XCTAssertFalse(ui.dispatchAction(action))
        ui.removeTab("controls")
        XCTAssertNil(ui.getTab("controls"))
        XCTAssertNotNil(ui.getTab("other"))
    }
}
