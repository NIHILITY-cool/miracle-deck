import XCTest
@testable import TokenMonitorProviders

final class MockProviderTests: XCTestCase {
    func testFixturesCoverCoreProviderCategories() {
        let categories = Set(MockProvider.sampleSnapshots().map(\.category))

        XCTAssertTrue(categories.contains(.api))
        XCTAssertTrue(categories.contains(.subscription))
        XCTAssertTrue(categories.contains(.relay))
    }
}
