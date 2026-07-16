import XCTest
import MiracleDeckCore
@testable import MiracleDeckUI

@MainActor
final class MiracleDeckUITests: XCTestCase {
    func testPanelCanBeConstructedWithNoSnapshots() {
        _ = MonitorPanelView(snapshots: [])
    }
}
