import XCTest
@testable import OpButtonSDK

final class PanelLayoutTests: XCTestCase {
    func testReplacingAndRemovingTreesDetachHandlersAndProviders() {
        let ui = OpButtonUI()
        let tab = ui.addTab("Lifecycle")
        let old = tab.vertical()
        let slider = old.addSlider("Speed").onChange { (_: OpButtonSliderAction) in XCTFail("Removed slider dispatched") }
        var samples = 0
        old.addStat("FPS").valueProvider { samples += 1; return "60" }
        let id = slider.internalId
        ui.markSent(ui.getRevision())
        let grid = tab.grid()
        XCTAssertTrue(ui.hasUnsent)
        XCTAssertGreaterThan(grid.internalId, id)
        ui.pollValues()
        XCTAssertEqual(samples, 0)
        XCTAssertFalse(ui.dispatchAction(OpButtonAction.fromJson(["widget_id": id])))
        let next = grid.addSlider("Next").onChange { (_: OpButtonSliderAction) in XCTFail("Removed tab dispatched") }
        ui.addTab("Spacing").vertical().addPadding(0)
        ui.removeTab(tab.id)
        XCTAssertFalse(ui.dispatchAction(OpButtonAction.fromJson(["widget_id": next.internalId])))
    }
    private func collect(_ node: [String: Any], _ ids: inout Set<Int>) throws {
        XCTAssertTrue(ids.insert(try XCTUnwrap(node["id"] as? Int)).inserted)
        for child in node["children"] as? [[String: Any]] ?? [] { try collect(child, &ids) }
    }

    func testRetainedLayoutContractAndTypedEvents() throws {
        let ui = OpButtonUI()
        let root = ui.addTab("Layout contract").vertical().gap(12).padding(8).density("compact")
        let row = root.addHorizontal().gap(8).align("end").justify("space-between").wrap(true)
        let button = row.addButton("Apply").width(140)
        row.addSelect("Language").options([["en", "English"], ["ru", "Русский"]])
            .defaultValue("en").fill(2).minWidth(160).maxWidth(480)
        let radio = root.addRadioGroup("Difficulty").options([["easy", "Easy"], ["hard", "Hard"]])
            .defaultValue("easy").optionDirection("horizontal")
        let slider = root.addSlider("Speed").range(0.5, 3, 0.1).defaultValue(1.5).unit("x").fill()
        root.addCollapsible("Advanced").gap(4).density("comfortable").addGroup("Group").addButton("Inside")
        let grid = root.addGrid().columns(3).minCellWidth(140).gap(8)
        for text in ["A", "B", "C"] { grid.addButton(text) }
        let identifier = button.internalId
        ui.markSent(ui.getRevision())
        button.width(160)
        XCTAssertTrue(ui.hasUnsent)
        XCTAssertEqual(identifier, button.internalId)
        let layout = ui.toJson()
        let tab = try XCTUnwrap((layout["tabs"] as? [[String: Any]])?.first)
        var ids: Set<Int> = [try XCTUnwrap(tab["id"] as? Int)]
        try collect(try XCTUnwrap(tab["layout"] as? [String: Any]), &ids)
        let collapsed = try XCTUnwrap((root.toJson()["children"] as? [[String: Any]])?[3])
        XCTAssertEqual((collapsed["children"] as? [[String: Any]])?.first?["gap"] as? Double, 4)
        var received = 0.0
        slider.onChange { (action: OpButtonSliderAction) in received = action.value }
        XCTAssertTrue(ui.dispatchAction(OpButtonAction.fromJson([
            "widget_id": slider.internalId, "action_type": "change", "payload": ["value": 1.7]])))
        XCTAssertEqual(received, 1.7)
        var choice = ""
        radio.onChange { (action: OpButtonRadioGroupAction) in choice = action.value }
        _ = ui.dispatchAction(OpButtonAction.fromJson([
            "widget_id": radio.internalId, "action_type": "change", "payload": ["value": "hard"]]))
        XCTAssertEqual(choice, "hard")
        let fixture = try JSONSerialization.data(withJSONObject: layout)
        print("OPBUTTON_LAYOUT_FIXTURE=" + String(decoding: fixture, as: UTF8.self))
        if let directory = ProcessInfo.processInfo.environment["OPBUTTON_LAYOUT_FIXTURE_DIR"] {
            try fixture.write(to: URL(fileURLWithPath: directory).appendingPathComponent("swift.json"))
        }
    }
}
