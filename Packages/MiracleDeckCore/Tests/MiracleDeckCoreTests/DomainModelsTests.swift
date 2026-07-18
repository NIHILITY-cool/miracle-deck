import XCTest
@testable import MiracleDeckCore

final class DomainModelsTests: XCTestCase {
    func testMoneyUsesDecimalAndKeepsCurrency() {
        let money = Money(amount: Decimal(string: "12.34")!, currencyCode: "CNY")

        XCTAssertEqual(money.amount, Decimal(string: "12.34"))
        XCTAssertEqual(money.currencyCode, "CNY")
    }

    func testUnknownUsageFieldsRemainNil() {
        let usage = UsageSummary(
            period: DateInterval(start: .now, duration: 60)
        )

        XCTAssertNil(usage.inputTokens)
        XCTAssertNil(usage.spend)
        XCTAssertFalse(usage.isEstimated)
    }

    func testQuotaResetCountIsOptional() {
        let quota = QuotaWindow(
            id: "weekly",
            title: "每周额度",
            remainingRatio: 0.5,
            resetsAt: nil
        )

        XCTAssertNil(quota.resetCount)
    }
}
