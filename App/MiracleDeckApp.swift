import SwiftUI
import MiracleDeckProviders
import MiracleDeckUI

@main
struct MiracleDeckApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        Settings {
#if DEBUG
            LayoutWorkbenchView(
                snapshots: MockProvider.sampleSnapshots(),
                targetStore: .shared
            )
#else
            SettingsPlaceholderView()
#endif
        }
    }
}

private struct SettingsPlaceholderView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.bar.xaxis")
                .font(.system(size: 32))
            Text("MiracleDeck")
                .font(.headline)
            Text("账户设置将在后续里程碑开放。")
                .foregroundStyle(.secondary)
        }
        .frame(width: 360, height: 180)
        .padding()
    }
}
