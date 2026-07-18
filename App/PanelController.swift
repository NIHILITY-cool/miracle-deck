import AppKit
import QuartzCore
import SwiftUI
import MiracleDeckCore
import MiracleDeckUI

@MainActor
final class PanelController {
    private let panel: MonitorPanel
    private let layoutStore: DeckLayoutStore

    init(
        snapshots: [ProviderSnapshot],
        layoutStore: DeckLayoutStore = .shared
    ) {
        let panelSize = NSSize(
            width: layoutStore.preset.panelWidth,
            height: layoutStore.preset.panelHeight
        )
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
            rootView: MonitorPanelView(
                snapshots: snapshots,
                layoutStore: layoutStore
            )
        )

        self.panel = panel
        self.layoutStore = layoutStore
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

        let panelSize = NSSize(
            width: layoutStore.preset.panelWidth,
            height: layoutStore.preset.panelHeight
        )
        panel.setContentSize(panelSize)

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

        let reduceMotion = NSWorkspace.shared.accessibilityDisplayShouldReduceMotion
        let startOrigin = NSPoint(x: origin.x, y: origin.y + 7)

        panel.alphaValue = reduceMotion ? 1 : 0
        panel.setFrameOrigin(reduceMotion ? origin : startOrigin)
        NSApp.activate(ignoringOtherApps: true)
        panel.makeKeyAndOrderFront(nil)

        guard !reduceMotion else {
            return
        }

        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.22
            context.timingFunction = CAMediaTimingFunction(
                controlPoints: 0.18,
                0.78,
                0.24,
                1
            )
            panel.animator().alphaValue = 1
            panel.animator().setFrameOrigin(origin)
        }
    }
}

private final class MonitorPanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
}
