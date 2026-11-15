import XCTest
@testable import OpButtonSDK

final class StateDeliveryTests: XCTestCase {
    func testFailedDeliveryRemainsPendingAndAcknowledgesOnlyItsSnapshot() {
        let journal = OpButtonAttributeJournal()
        let first = journal.snapshot(["level": 1])
        XCTAssertEqual(journal.snapshot(["level": 1])["level"] as? Int, 1)
        journal.acknowledge(first)
        XCTAssertEqual(journal.snapshot(["level": 2])["level"] as? Int, 2)
        journal.acknowledge(journal.snapshot(["level": 2]))
        XCTAssertTrue(journal.snapshot(["level": 2]).isEmpty)
    }

    func testMutableValuesAreDetachedAndNativeTypesSurvive() {
        let journal = OpButtonAttributeJournal()
        let nested = NSMutableDictionary(dictionary: ["level": 1])
        let values: [String: Any] = ["state": nested, "optional": NSNull(), "enabled": false]
        let snapshot = journal.snapshot(values)
        nested["level"] = 2
        journal.acknowledge(snapshot)
        XCTAssertEqual((snapshot["state"] as? [String: Any])?["level"] as? Int, 1)
        XCTAssertTrue(snapshot["optional"] is NSNull)
        XCTAssertNotNil(journal.snapshot(values)["state"])
        XCTAssertEqual(journal.snapshot(["enabled": "false"])["enabled"] as? String, "false")
    }

    func testPanelAcknowledgementDoesNotHideNewerEditsOrMoveBackwards() {
        let ui = OpButtonUI()
        let button = ui.addTab("Controls").vertical().addButton("Run")
        let sent = ui.getRevision()
        button.disabled(true)
        ui.markSent(sent)
        XCTAssertTrue(ui.hasUnsent)
        ui.markSent(ui.getRevision())
        ui.markSent(sent)
        XCTAssertFalse(ui.hasUnsent)
    }

    func testBackgroundSnapshotReadsProvidersOnTheMainThread() {
        let ui = OpButtonUI()
        let sampled = expectation(description: "provider sampled")
        ui.addTab("Controls").vertical().addStat("FPS").valueProvider {
            XCTAssertTrue(Thread.isMainThread)
            return "60"
        }
        DispatchQueue.global().async {
            OpButtonMainThread.sync {
                ui.pollValues()
                XCTAssertTrue(ui.hasUnsent)
            }
            sampled.fulfill()
        }
        wait(for: [sampled], timeout: 2)
    }

    func testPanelSnapshotDetachesMutableHostValues() throws {
        let children = NSMutableArray(array: [["id": 1]])
        let snapshot = try XCTUnwrap(OpButtonPanelSnapshot(["revision": 7, "children": children]))
        children.removeAllObjects()
        XCTAssertEqual(snapshot.revision, 7)
        XCTAssertEqual((snapshot.layout["children"] as? [Any])?.count, 1)
    }
}
