import SwiftUI

@main
struct TokenMonitorApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        Settings {
            SettingsPlaceholderView()
        }
    }
}

private struct SettingsPlaceholderView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.bar.xaxis")
                .font(.system(size: 32))
            Text("Token Monitor")
                .font(.headline)
            Text("账户设置将在后续里程碑开放。")
                .foregroundStyle(.secondary)
        }
        .frame(width: 360, height: 180)
        .padding()
    }
}
