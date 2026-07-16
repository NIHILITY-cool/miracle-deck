import AppKit
import TokenMonitorProviders
import TokenMonitorUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var panelController: PanelController?
    private var statusItemController: StatusItemController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        let panelController = PanelController(
            snapshots: MockProvider.sampleSnapshots()
        )
        let statusItemController = StatusItemController { [weak panelController] button in
            panelController?.toggle(relativeTo: button)
        }

        self.panelController = panelController
        self.statusItemController = statusItemController
    }

    func applicationDidResignActive(_ notification: Notification) {
        panelController?.hide()
    }
}
