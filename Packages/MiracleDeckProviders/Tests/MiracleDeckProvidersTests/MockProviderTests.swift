import XCTest
@testable import MiracleDeckProviders

final class MockProviderTests: XCTestCase {
    func testFixturesCoverCoreProviderCategories() {
        let categories = Set(MockProvider.sampleSnapshots().map(\.category))

        XCTAssertTrue(categories.contains(.api))
        XCTAssertTrue(categories.contains(.subscription))
        XCTAssertTrue(categories.contains(.relay))
    }

    func testBalanceFixturesIncludeRecentSpend() {
        let balanceSnapshots = MockProvider.sampleSnapshots().filter {
            $0.balance != nil
        }

        XCTAssertFalse(balanceSnapshots.isEmpty)
        XCTAssertTrue(
            balanceSnapshots.allSatisfy {
                $0.usage.contains { $0.spend != nil }
            }
        )
    }

    func testWeeklyQuotaFixtureIncludesResetCount() {
        let weeklyQuota = MockProvider.sampleSnapshots()
            .flatMap(\.quotaWindows)
            .first { $0.id == "weekly" }

        XCTAssertEqual(weeklyQuota?.resetCount, 4)
    }
}
