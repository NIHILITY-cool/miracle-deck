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
        XCTAssertEqual(MonitorPanelView.preferredSize.width, 294)
        XCTAssertEqual(MonitorPanelView.preferredSize.height, 320)
    }

    func testDefaultLayoutMatchesPanelSizeAndCanBeEditedInMemory() {
        let store = DeckLayoutStore(
            preset: .default,
            persistsChanges: false
        )

        XCTAssertEqual(store.preset.panelSize, MonitorPanelView.preferredSize)
        XCTAssertEqual(store.preset.compactStatusSize, 8)
        XCTAssertEqual(store.preset.listMetricFontSize, 12)
        XCTAssertEqual(
            store.preset.compactQuotaPrimary,
            DeckLayoutPoint(x: 15, y: 43)
        )
        XCTAssertEqual(
            store.preset.compactBalancePrimary,
            DeckLayoutPoint(x: 15, y: 51)
        )
        XCTAssertEqual(
            store.preset.expandedBalanceInsights,
            DeckLayoutPoint(x: 20, y: 158)
        )

        var edited = store.preset
        edited.compactQuotaPrimary.y += 5
        edited.expandedQuotaPrimary.y += 8
        store.apply(edited, persist: false)

        XCTAssertEqual(store.preset.compactQuotaPrimary.y, 48)
        XCTAssertEqual(store.preset.compactBalancePrimary.y, 51)
        XCTAssertEqual(store.preset.expandedQuotaPrimary.y, 84)
        XCTAssertEqual(store.preset.expandedBalancePrimary.y, 90)
    }

    func testLayoutWorkbenchCanBeConstructed() {
        let store = DeckLayoutStore(
            preset: .default,
            persistsChanges: false
        )
        _ = LayoutWorkbenchView(
            snapshots: MockProvider.sampleSnapshots(),
            targetStore: store
        )
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
        XCTAssertEqual(
            updateTimestamp(date, timeZone: timeZone),
            "7月19日 01:35 更新"
        )
    }

    func testProviderOrderMovesDraggedItemToDestination() {
        let first = UUID()
        let second = UUID()
        let third = UUID()

        XCTAssertEqual(
            reorderedProviderIDs(
                [first, second, third],
                moving: first,
                to: third
            ),
            [second, third, first]
        )
    }

    func testRelativeProviderSelectionWrapsInBothDirections() {
        let first = UUID()
        let second = UUID()
        let third = UUID()
        let ids = [first, second, third]

        XCTAssertEqual(
            relativeProviderID(in: ids, from: third, offset: 1),
            first
        )
        XCTAssertEqual(
            relativeProviderID(in: ids, from: first, offset: -1),
            third
        )
    }

    func testProviderListViewportNeverExceedsThreeRows() {
        XCTAssertEqual(providerListViewportHeight(accountCount: 1), 34)
        XCTAssertEqual(providerListViewportHeight(accountCount: 3), 108)
        XCTAssertEqual(providerListViewportHeight(accountCount: 12), 108)
    }

    func testCardNavigationAcceptsHorizontalAndVerticalGestures() {
        XCTAssertEqual(
            cardNavigationOffset(
                horizontal: -80,
                vertical: 4,
                verticalPositiveMeansPrevious: true
            ),
            1
        )
        XCTAssertEqual(
            cardNavigationOffset(
                horizontal: 3,
                vertical: 80,
                verticalPositiveMeansPrevious: false
            ),
            1
        )
        XCTAssertEqual(
            cardNavigationOffset(
                horizontal: 3,
                vertical: 80,
                verticalPositiveMeansPrevious: true
            ),
            -1
        )
    }

    func testCardScrollRequiresDeliberateGestureAndIgnoresMomentum() {
        var gate = CardScrollGestureGate()
        gate.beginGesture()

        XCTAssertNil(
            gate.consume(
                delta: CGSize(width: 0, height: -36),
                hasPreciseDeltas: true,
                isMomentum: false,
                phaseIsEmpty: false,
                now: 1
            )
        )
        XCTAssertEqual(
            gate.consume(
                delta: CGSize(width: 0, height: -38),
                hasPreciseDeltas: true,
                isMomentum: false,
                phaseIsEmpty: false,
                now: 1.1
            ),
            1
        )
        XCTAssertNil(
            gate.consume(
                delta: CGSize(width: 0, height: -160),
                hasPreciseDeltas: true,
                isMomentum: false,
                phaseIsEmpty: false,
                now: 1.8
            )
        )

        gate.endGesture()
        XCTAssertNil(
            gate.consume(
                delta: CGSize(width: 0, height: -180),
                hasPreciseDeltas: true,
                isMomentum: true,
                phaseIsEmpty: false,
                now: 2
            )
        )

        gate.beginGesture()
        XCTAssertEqual(
            gate.consume(
                delta: CGSize(width: 90, height: 0),
                hasPreciseDeltas: true,
                isMomentum: false,
                phaseIsEmpty: false,
                now: 2.2
            ),
            -1
        )
    }

    func testRenderPanelWhenCapturePathIsProvided() throws {
        guard let capturePath = ProcessInfo.processInfo.environment["MIRACLEDECK_CAPTURE_PATH"] else {
            throw XCTSkip("Set MIRACLEDECK_CAPTURE_PATH to render a visual QA image.")
        }

        let size = MonitorPanelView.preferredSize
        let snapshots = MockProvider.sampleSnapshots()
        let preferredCategory: ProviderCategory =
            switch ProcessInfo.processInfo.environment[
                "MIRACLEDECK_CAPTURE_PROVIDER"
            ] {
            case "api": .api
            case "relay": .relay
            default: .subscription
            }
        let captureSnapshots = snapshots.sorted {
            if $0.category == preferredCategory {
                return true
            }
            if $1.category == preferredCategory {
                return false
            }
            return false
        }
        let layoutStore = DeckLayoutStore(
            preset: .default,
            persistsChanges: false
        )
        let rootView = MonitorPanelView(
            snapshots: captureSnapshots,
            initialMode:
                ProcessInfo.processInfo.environment[
                    "MIRACLEDECK_CAPTURE_MODE"
                ] == "card"
                    ? .card
                    : .arrangement,
            layoutStore: layoutStore
        )
            .environment(
                \.colorScheme,
                ProcessInfo.processInfo.environment["MIRACLEDECK_CAPTURE_SCHEME"] == "dark"
                    ? .dark
                    : .light
            )
            .environment(
                \.panelTone,
                PanelTone(
                    rawValue: ProcessInfo.processInfo.environment[
                        "MIRACLEDECK_CAPTURE_TONE"
                    ] ?? ""
                ) ?? .pearlGlass
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

    func testRenderLayoutWorkbenchWhenCapturePathIsProvided() throws {
        guard let capturePath = ProcessInfo.processInfo.environment[
            "MIRACLEDECK_CAPTURE_WORKBENCH_PATH"
        ] else {
            throw XCTSkip(
                "Set MIRACLEDECK_CAPTURE_WORKBENCH_PATH to render the workbench."
            )
        }

        let store = DeckLayoutStore(
            preset: .default,
            persistsChanges: false
        )
        let size = CGSize(width: 760, height: 480)
        let rootView = LayoutWorkbenchView(
            snapshots: MockProvider.sampleSnapshots(),
            targetStore: store
        )
        .environment(\.colorScheme, .light)
        let hostingView = NSHostingView(rootView: rootView)
        hostingView.frame = NSRect(origin: .zero, size: size)
        hostingView.layoutSubtreeIfNeeded()

        guard let bitmap = hostingView.bitmapImageRepForCachingDisplay(
            in: hostingView.bounds
        ) else {
            XCTFail("Unable to allocate workbench snapshot.")
            return
        }

        hostingView.cacheDisplay(in: hostingView.bounds, to: bitmap)

        guard let png = bitmap.representation(
            using: .png,
            properties: [:]
        ) else {
            XCTFail("Unable to encode workbench snapshot.")
            return
        }

        try png.write(
            to: URL(fileURLWithPath: capturePath),
            options: .atomic
        )
    }
}
