import SwiftUI
import TokenMonitorCore

public struct MonitorPanelView: View {
    private let snapshots: [ProviderSnapshot]
    @State private var selectedID: UUID?

    public init(snapshots: [ProviderSnapshot]) {
        self.snapshots = snapshots
        self._selectedID = State(initialValue: snapshots.first?.id)
    }

    public var body: some View {
        VStack(spacing: 14) {
            header

            if let selectedSnapshot {
                ProviderHeroCard(snapshot: selectedSnapshot)
            }

            providerList
            footer
        }
        .padding(16)
        .frame(width: 380, height: 520)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private var selectedSnapshot: ProviderSnapshot? {
        snapshots.first(where: { $0.id == selectedID }) ?? snapshots.first
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Token Monitor")
                    .font(.headline)
                Text("所有账户")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button {
            } label: {
                Image(systemName: "arrow.clockwise")
            }
            .buttonStyle(.plain)
            .help("刷新")

            Button {
                NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
            } label: {
                Image(systemName: "gearshape")
            }
            .buttonStyle(.plain)
            .help("设置")
        }
    }

    private var providerList: some View {
        VStack(spacing: 8) {
            ForEach(snapshots) { snapshot in
                Button {
                    selectedID = snapshot.id
                } label: {
                    ProviderCompactRow(
                        snapshot: snapshot,
                        isSelected: selectedID == snapshot.id
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var footer: some View {
        HStack {
            Label("Mock 数据", systemImage: "checkmark.shield")
            Spacer()
            Text("刚刚更新")
        }
        .font(.caption2)
        .foregroundStyle(.secondary)
    }
}

private struct ProviderHeroCard: View {
    let snapshot: ProviderSnapshot

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                ProviderMark(name: snapshot.displayName, status: snapshot.status)
                VStack(alignment: .leading, spacing: 2) {
                    Text(snapshot.displayName)
                        .font(.headline)
                    Text(snapshot.accountName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                StatusBadge(status: snapshot.status)
            }

            VStack(alignment: .leading, spacing: 5) {
                Text(primaryLabel)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(primaryValue)
                    .font(.system(size: 34, weight: .semibold, design: .rounded))
                    .contentTransition(.numericText())
            }

            if let quota = snapshot.quotaWindows.first,
               let remainingRatio = quota.remainingRatio {
                VStack(alignment: .leading, spacing: 6) {
                    ProgressView(value: decimalDouble(remainingRatio))
                        .tint(statusColor(snapshot.status))
                    HStack {
                        Text(quota.title)
                        Spacer()
                        Text("剩余 \(percentage(remainingRatio))")
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
            }

            Text(snapshot.source.label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(
                colors: [
                    statusColor(snapshot.status).opacity(0.20),
                    Color.accentColor.opacity(0.06)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(.white.opacity(0.12), lineWidth: 1)
        }
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var primaryLabel: String {
        snapshot.balance == nil ? "套餐剩余额度" : "可用余额"
    }

    private var primaryValue: String {
        if let balance = snapshot.balance {
            return "\(balance.currencyCode) \(balance.amount)"
        }
        if let ratio = snapshot.quotaWindows.first?.remainingRatio {
            return percentage(ratio)
        }
        return "—"
    }
}

private struct ProviderCompactRow: View {
    let snapshot: ProviderSnapshot
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 10) {
            ProviderMark(name: snapshot.displayName, status: snapshot.status)

            VStack(alignment: .leading, spacing: 2) {
                Text(snapshot.displayName)
                    .font(.subheadline.weight(.medium))
                Text(snapshot.accountName)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text(metric)
                .font(.subheadline.monospacedDigit())

            Circle()
                .fill(statusColor(snapshot.status))
                .frame(width: 7, height: 7)
                .accessibilityLabel(statusText(snapshot.status))
        }
        .padding(.horizontal, 11)
        .padding(.vertical, 9)
        .background(
            isSelected ? Color.primary.opacity(0.07) : Color.clear,
            in: RoundedRectangle(cornerRadius: 12, style: .continuous)
        )
    }

    private var metric: String {
        if let balance = snapshot.balance {
            return "\(balance.currencyCode) \(balance.amount)"
        }
        if let ratio = snapshot.quotaWindows.first?.remainingRatio {
            return percentage(ratio)
        }
        return "—"
    }
}

private struct ProviderMark: View {
    let name: String
    let status: ProviderStatus

    var body: some View {
        Text(String(name.prefix(1)))
            .font(.system(size: 14, weight: .bold, design: .rounded))
            .frame(width: 30, height: 30)
            .background(
                statusColor(status).opacity(0.16),
                in: RoundedRectangle(cornerRadius: 9, style: .continuous)
            )
            .foregroundStyle(statusColor(status))
    }
}

private struct StatusBadge: View {
    let status: ProviderStatus

    var body: some View {
        Text(statusText(status))
            .font(.caption2.weight(.semibold))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                statusColor(status).opacity(0.14),
                in: Capsule()
            )
            .foregroundStyle(statusColor(status))
    }
}

private func statusColor(_ status: ProviderStatus) -> Color {
    switch status {
    case .healthy:
        return .green
    case .warning:
        return .orange
    case .critical:
        return .red
    case .unavailable:
        return .secondary
    }
}

private func statusText(_ status: ProviderStatus) -> String {
    switch status {
    case .healthy:
        return "正常"
    case .warning:
        return "注意"
    case .critical:
        return "紧急"
    case .unavailable:
        return "不可用"
    }
}

private func decimalDouble(_ value: Decimal) -> Double {
    NSDecimalNumber(decimal: value).doubleValue
}

private func percentage(_ value: Decimal) -> String {
    "\(Int((decimalDouble(value) * 100).rounded()))%"
}
