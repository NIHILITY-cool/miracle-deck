import XCTest
import TokenMonitorCore
@testable import TokenMonitorUI

@MainActor
final class TokenMonitorUITests: XCTestCase {
    func testPanelCanBeConstructedWithNoSnapshots() {
        _ = MonitorPanelView(snapshots: [])
    }
}
