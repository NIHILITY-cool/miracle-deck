import AppKit

@MainActor
final class StatusItemController: NSObject {
    private let statusItem: NSStatusItem
    private let onToggle: (NSStatusBarButton) -> Void

    init(onToggle: @escaping (NSStatusBarButton) -> Void) {
        self.statusItem = NSStatusBar.system.statusItem(
            withLength: NSStatusItem.squareLength
        )
        self.onToggle = onToggle
        super.init()

        guard let button = statusItem.button else {
            return
        }

        button.image = NSImage(
            systemSymbolName: "chart.bar.xaxis",
            accessibilityDescription: "Token Monitor"
        )
        button.image?.isTemplate = true
        button.target = self
        button.action = #selector(togglePanel)
        button.sendAction(on: [.leftMouseUp, .rightMouseUp])
    }

    @objc
    private func togglePanel() {
        guard let button = statusItem.button else {
            return
        }
        onToggle(button)
    }
}
