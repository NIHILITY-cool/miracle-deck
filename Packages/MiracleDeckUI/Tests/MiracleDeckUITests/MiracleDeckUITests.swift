import AppKit
import SwiftUI
import XCTest
import MiracleDeckCore
import MiracleDeckProviders
@testable import MiracleDeckUI

@MainActor
final class MiracleDeckUITests: XCTestCase {
    func testPanelCanBeConstructedWithNoSnapshots() {
        _ = MonitorPanelView(snapshots: [])
    }

    func testPanelUsesCompactPreferredSize() {
        XCTAssertEqual(MonitorPanelView.preferredSize.width, 368)
        XCTAssertEqual(MonitorPanelView.preferredSize.height, 400)
    }

    func testQuotaResetUsesSpecificDateAndTime() {
        let timeZone = TimeZone(secondsFromGMT: 8 * 60 * 60)!
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let date = calendar.date(
            from: DateComponents(
                year: 2026,
                month: 7,
                day: 19,
                hour: 1,
                minute: 35
            )
        )!

        XCTAssertEqual(
            resetTimestamp(date, timeZone: timeZone),
            "7月19日 01:35"
        )
        XCTAssertEqual(
            resetTimestamp(nil, timeZone: timeZone),
            "时间未知"
        )
        XCTAssertEqual(
            resetDate(date, timeZone: timeZone),
            "7月19日"
        )
        XCTAssertEqual(
            resetDate(nil, timeZone: timeZone),
            "日期未知"
        )
    }

    func testRenderPanelWhenCapturePathIsProvided() throws {
        guard let capturePath = ProcessInfo.processInfo.environment["MIRACLEDECK_CAPTURE_PATH"] else {
            throw XCTSkip("Set MIRACLEDECK_CAPTURE_PATH to render a visual QA image.")
        }

        let size = MonitorPanelView.preferredSize
        let snapshots = MockProvider.sampleSnapshots()
        let subscriptionFirst = snapshots.sorted {
            if $0.category == .subscription {
                return true
            }
            if $1.category == .subscription {
                return false
            }
            return false
        }
        let rootView = MonitorPanelView(snapshots: subscriptionFirst)
            .environment(
                \.colorScheme,
                ProcessInfo.processInfo.environment["MIRACLEDECK_CAPTURE_SCHEME"] == "dark"
                    ? .dark
                    : .light
            )
            .environment(\.deckAnimationsEnabled, false)
        let hostingView = NSHostingView(rootView: rootView)
        hostingView.frame = NSRect(origin: .zero, size: size)
        hostingView.layoutSubtreeIfNeeded()

        guard let bitmap = hostingView.bitmapImageRepForCachingDisplay(in: hostingView.bounds) else {
            XCTFail("Unable to allocate panel snapshot.")
            return
        }

        hostingView.cacheDisplay(in: hostingView.bounds, to: bitmap)

        guard let png = bitmap.representation(using: .png, properties: [:]) else {
            XCTFail("Unable to encode panel snapshot.")
            return
        }

        try png.write(to: URL(fileURLWithPath: capturePath), options: .atomic)
    }
}
