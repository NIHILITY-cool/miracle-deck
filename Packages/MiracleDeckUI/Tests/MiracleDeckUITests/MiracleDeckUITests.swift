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

    func testRenderPanelWhenCapturePathIsProvided() throws {
        guard let capturePath = ProcessInfo.processInfo.environment["MIRACLEDECK_CAPTURE_PATH"] else {
            throw XCTSkip("Set MIRACLEDECK_CAPTURE_PATH to render a visual QA image.")
        }

        let size = MonitorPanelView.preferredSize
        let rootView = MonitorPanelView(snapshots: MockProvider.sampleSnapshots())
            .environment(\.colorScheme, .light)
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
