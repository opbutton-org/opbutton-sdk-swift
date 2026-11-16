import XCTest
@testable import OpButtonSDK

final class JsonPanelTests: XCTestCase {
    func testJSONPreservesPropertiesAndNativeBuilders() throws {
        let ui = OpButtonUI()
        let tab = ui.addTab("json").setName("JSON")
        let description: [String: Any] = [
            "type": "layout", "direction": "grid", "gridColumns": 3, "gap": 8,
            "placement": ["width": "fill", "weight": 2], "future": ["enabled": true],
            "children": [["type": "slider", "id": "speed", "label": "Speed", "min": 0.5, "max": 3, "step": 0.1]]
        ]
        var received = ""
        let root = try tab.setJson(description) { identifier, action in
            received = identifier
            XCTAssertEqual(action.payload?["value"] as? Double, 1.5)
        }
        root.padding(4).addButton("Native")
        let json = root.toJson()
        XCTAssertEqual(json["gap"] as? Int, 8)
        XCTAssertEqual(json["padding"] as? Double, 4)
        XCTAssertEqual((json["future"] as? [String: Bool])?["enabled"], true)
        let children = try XCTUnwrap(json["children"] as? [[String: Any]])
        XCTAssertEqual(children.count, 2)
        let id = try XCTUnwrap(children[0]["id"] as? Int)
        let action = OpButtonAction.fromJson(["widget_id": id, "payload": ["value": 1.5]])
        XCTAssertTrue(ui.dispatchAction(action))
        XCTAssertEqual(received, "speed")
        XCTAssertThrowsError(try tab.setJson(["type": "layout", "direction": "vertical", "children": [42]]))
        XCTAssertTrue(ui.dispatchAction(action))
        _ = try tab.setJson(description) { _, _ in ui.removeTab("json") }
        XCTAssertFalse(ui.dispatchAction(action))
        let next = try XCTUnwrap(tab.getLayout()?.toJson()["children"] as? [[String: Any]])
        let nextId = try XCTUnwrap(next.first?["id"] as? Int)
        XCTAssertTrue(ui.dispatchAction(OpButtonAction.fromJson(["widget_id": nextId])))
        XCTAssertFalse(ui.dispatchAction(OpButtonAction.fromJson(["widget_id": nextId])))
    }
}
