import AppKit
import SwiftUI
import MiracleDeckCore
import MiracleDeckUI

@MainActor
final class PanelController {
    private let panel: MonitorPanel
    private let panelSize = NSSize(width: 380, height: 520)

    init(snapshots: [ProviderSnapshot]) {
        let panel = MonitorPanel(
            contentRect: NSRect(origin: .zero, size: panelSize),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: true
        )

        panel.level = .floating
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.hidesOnDeactivate = true
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.contentViewController = NSHostingController(
            rootView: MonitorPanelView(snapshots: snapshots)
        )

        self.panel = panel
    }

    func toggle(relativeTo button: NSStatusBarButton) {
        if panel.isVisible {
            hide()
        } else {
            show(relativeTo: button)
        }
    }

    func hide() {
        panel.orderOut(nil)
    }

    private func show(relativeTo button: NSStatusBarButton) {
        guard let buttonWindow = button.window else {
            return
        }

        let anchor = buttonWindow.convertToScreen(button.bounds)
        let screenFrame = buttonWindow.screen?.visibleFrame ?? NSScreen.main?.visibleFrame ?? .zero

        var origin = NSPoint(
            x: anchor.midX - panelSize.width / 2,
            y: anchor.minY - panelSize.height - 8
        )

        origin.x = min(
            max(origin.x, screenFrame.minX + 8),
            screenFrame.maxX - panelSize.width - 8
        )
        origin.y = max(origin.y, screenFrame.minY + 8)

        panel.setFrameOrigin(origin)
        NSApp.activate(ignoringOtherApps: true)
        panel.makeKeyAndOrderFront(nil)
    }
}

private final class MonitorPanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
}
