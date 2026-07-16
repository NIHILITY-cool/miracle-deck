import SwiftUI
import MiracleDeckCore

struct DeckAnimationsEnabledKey: EnvironmentKey {
    static let defaultValue = true
}

extension EnvironmentValues {
    var deckAnimationsEnabled: Bool {
        get { self[DeckAnimationsEnabledKey.self] }
        set { self[DeckAnimationsEnabledKey.self] = newValue }
    }
}

public struct MonitorPanelView: View {
    public static let preferredSize = CGSize(width: 368, height: 400)

    private let snapshots: [ProviderSnapshot]
    @State private var selectedID: UUID?
    @Namespace private var selectionNamespace
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public init(snapshots: [ProviderSnapshot]) {
        self.snapshots = snapshots
        self._selectedID = State(initialValue: snapshots.first?.id)
    }

    public var body: some View {
        let palette = DeckPalette(colorScheme: colorScheme)

        VStack(spacing: 10) {
            header(palette: palette)

            if let selectedSnapshot {
                ProviderHeroCard(snapshot: selectedSnapshot, palette: palette)
                    .id(selectedSnapshot.id)
                    .background {
                        HeroAmbientGlow(
                            status: selectedSnapshot.status,
                            palette: palette
                        )
                    }
                    .transition(heroTransition)
            }

            providerList(palette: palette)
            footer(palette: palette)
        }
        .padding(14)
        .frame(
            width: Self.preferredSize.width,
            height: Self.preferredSize.height,
            alignment: .top
        )
        .background(PanelBackground(palette: palette))
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(palette.outerBorder, lineWidth: 1)
        }
    }

    private var selectedSnapshot: ProviderSnapshot? {
        snapshots.first(where: { $0.id == selectedID }) ?? snapshots.first
    }

    private var selectionAnimation: Animation {
        reduceMotion
            ? .linear(duration: 0.01)
            : .spring(response: 0.34, dampingFraction: 0.86)
    }

    private var heroTransition: AnyTransition {
        guard !reduceMotion else {
            return .opacity
        }

        return .asymmetric(
            insertion: .opacity
                .combined(with: .scale(scale: 0.985))
                .combined(with: .offset(y: 5)),
            removal: .opacity
                .combined(with: .scale(scale: 0.995))
        )
    }

    private func header(palette: DeckPalette) -> some View {
        HStack(spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                Text("MIRACLEDECK")
                    .font(.system(size: 13, weight: .semibold))
                    .tracking(1.8)
                    .foregroundStyle(palette.primaryText)

                Text("\(snapshots.count) 个账户")
                    .font(.system(size: 10.5, weight: .medium))
                    .foregroundStyle(palette.secondaryText)
            }

            Spacer()

            HeaderButton(systemName: "arrow.clockwise", help: "刷新", palette: palette)

            HeaderButton(systemName: "gearshape", help: "设置", palette: palette) {
                NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
            }
        }
        .frame(height: 30)
    }

    private func providerList(palette: DeckPalette) -> some View {
        VStack(spacing: 4) {
            ForEach(snapshots) { snapshot in
                Button {
                    withAnimation(selectionAnimation) {
                        selectedID = snapshot.id
                    }
                } label: {
                    ProviderCompactRow(
                        snapshot: snapshot,
                        isSelected: selectedID == snapshot.id,
                        palette: palette,
                        selectionNamespace: selectionNamespace
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func footer(palette: DeckPalette) -> some View {
        HStack(spacing: 5) {
            Circle()
                .fill(palette.healthy)
                .frame(width: 5, height: 5)

            Text("Mock 数据")
            Text("·")
            Text("刚刚更新")

            Spacer()

            Text("⌘R 刷新")
        }
        .font(.system(size: 9.5, weight: .medium))
        .foregroundStyle(palette.tertiaryText)
        .frame(height: 12)
    }
}

private struct HeaderButton: View {
    let systemName: String
    let help: String
    let palette: DeckPalette
    var action: () -> Void = {}

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 11, weight: .semibold))
                .frame(width: 26, height: 26)
                .background(palette.controlFill, in: Circle())
                .overlay {
                    Circle()
                        .stroke(palette.controlBorder, lineWidth: 1)
                }
        }
        .buttonStyle(.plain)
        .foregroundStyle(palette.secondaryText)
        .help(help)
    }
}

private struct ProviderHeroCard: View {
    let snapshot: ProviderSnapshot
    let palette: DeckPalette

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            HeroBackground(status: snapshot.status, palette: palette)

            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .top, spacing: 8) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("\(snapshot.displayName) · \(snapshot.accountName)".uppercased())
                            .font(.system(size: 11.5, weight: .semibold))
                            .tracking(1.25)
                            .lineLimit(1)

                        Text(primaryLabel)
                            .font(.system(size: 11, weight: .medium))
                    }

                    Spacer()

                    StatusIndicator(status: snapshot.status, palette: palette)
                }

                Spacer(minLength: 4)

                Text(primaryValue)
                    .font(.system(size: primaryFontSize, weight: .medium))
                    .fontWidth(.condensed)
                    .monospacedDigit()
                    .tracking(-1.7)
                    .contentTransition(.numericText())

                Spacer(minLength: 6)

                if let quota = snapshot.quotaWindows.first,
                   let remainingRatio = quota.remainingRatio {
                    VStack(alignment: .leading, spacing: 5) {
                        QuotaProgressBar(
                            value: decimalDouble(remainingRatio),
                            status: snapshot.status,
                            palette: palette
                        )

                        HStack {
                            Text(quota.title)
                            Spacer()
                            Text(resetTimestamp(quota.resetsAt))
                        }
                        .font(.system(size: 9.5, weight: .medium))
                        .foregroundStyle(palette.tertiaryText)
                    }
                    .padding(.trailing, weeklyQuota == nil ? 42 : 88)
                } else {
                    Text(snapshot.source.label)
                        .font(.system(size: 9.5, weight: .medium))
                        .foregroundStyle(palette.tertiaryText)
                        .padding(.trailing, 42)
                }
            }
            .padding(15)
            .foregroundStyle(palette.primaryText)

            if let weeklyQuota,
               let weeklyRemainingRatio = weeklyQuota.remainingRatio {
                WeeklyQuotaBadge(
                    remainingRatio: weeklyRemainingRatio,
                    resetsAt: weeklyQuota.resetsAt,
                    palette: palette
                )
                .padding(.trailing, 14)
                .padding(.bottom, 13)
            } else {
                ProviderMark(name: snapshot.displayName, palette: palette, size: 34)
                    .padding(14)
            }
        }
        .frame(height: 154)
        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .stroke(palette.heroBorder, lineWidth: 1)
        }
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
        return "暂无"
    }

    private var primaryFontSize: CGFloat {
        snapshot.balance == nil ? 46 : 38
    }

    private var weeklyQuota: QuotaWindow? {
        guard let primaryQuota = snapshot.quotaWindows.first else {
            return nil
        }

        return snapshot.quotaWindows.first {
            $0.id != primaryQuota.id
                && ($0.id.localizedCaseInsensitiveContains("week")
                    || $0.title.localizedCaseInsensitiveContains("周"))
        }
    }
}

private struct WeeklyQuotaBadge: View {
    let remainingRatio: Decimal
    let resetsAt: Date?
    let palette: DeckPalette

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(alignment: .firstTextBaseline, spacing: 5) {
                Text("本周")
                    .font(.system(size: 8.5, weight: .semibold))
                    .tracking(0.5)
                    .foregroundStyle(palette.tertiaryText)

                Spacer(minLength: 0)

                Text(percentage(remainingRatio))
                    .font(.system(size: 12.5, weight: .semibold))
                    .fontWidth(.condensed)
                    .monospacedDigit()
                    .foregroundStyle(palette.primaryText)
            }

            Text(resetDate(resetsAt))
                .font(.system(size: 8.5, weight: .medium))
                .monospacedDigit()
                .foregroundStyle(palette.secondaryText)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .frame(width: 76)
        .background(
            palette.weeklyFill,
            in: RoundedRectangle(cornerRadius: 11, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 11, style: .continuous)
                .stroke(palette.weeklyBorder, lineWidth: 1)
        }
    }
}

private struct HeroBackground: View {
    let status: ProviderStatus
    let palette: DeckPalette

    var body: some View {
        ZStack {
            palette.heroBase

            RadialGradient(
                colors: [palette.heroCool.opacity(0.92), .clear],
                center: .topTrailing,
                startRadius: 0,
                endRadius: 180
            )

            RadialGradient(
                colors: [palette.heroGlow(status).opacity(0.86), .clear],
                center: .bottomLeading,
                startRadius: 0,
                endRadius: 190
            )

            LinearGradient(
                colors: [
                    Color.white.opacity(palette.isDark ? 0.02 : 0.18),
                    palette.heroWarm(status).opacity(palette.isDark ? 0.24 : 0.36)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
}

private struct HeroAmbientGlow: View {
    let status: ProviderStatus
    let palette: DeckPalette

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(palette.heroAmbient(status).opacity(palette.isDark ? 0.14 : 0.22))
                .blur(radius: 24)
                .scaleEffect(x: 1.025, y: 0.82)
                .offset(y: 9)

            RadialGradient(
                colors: [
                    palette.heroCool.opacity(palette.isDark ? 0.12 : 0.24),
                    .clear
                ],
                center: .topTrailing,
                startRadius: 10,
                endRadius: 170
            )
            .blur(radius: 12)
            .padding(-8)
        }
        .allowsHitTesting(false)
    }
}

private struct QuotaProgressBar: View {
    let value: Double
    let status: ProviderStatus
    let palette: DeckPalette
    @State private var displayedValue = 0.0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.deckAnimationsEnabled) private var animationsEnabled

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(palette.progressTrack)

                Capsule()
                    .fill(
                        LinearGradient(
                            colors: palette.progressColors(status),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(
                        width: max(
                            5,
                            geometry.size.width * min(max(displayedValue, 0), 1)
                        )
                    )
                    .animation(
                        reduceMotion || !animationsEnabled
                            ? nil
                            : .spring(response: 0.52, dampingFraction: 0.88)
                                .delay(0.04),
                        value: displayedValue
                    )
            }
        }
        .frame(height: 5)
        .accessibilityValue("\(Int((value * 100).rounded()))%")
        .onAppear {
            displayedValue = value
        }
        .onChange(of: value) { _, newValue in
            displayedValue = newValue
        }
    }
}

private struct ProviderCompactRow: View {
    let snapshot: ProviderSnapshot
    let isSelected: Bool
    let palette: DeckPalette
    let selectionNamespace: Namespace.ID

    var body: some View {
        ZStack {
            if isSelected {
                RoundedRectangle(cornerRadius: 13, style: .continuous)
                    .fill(palette.selectedRow)
                    .overlay {
                        RoundedRectangle(cornerRadius: 13, style: .continuous)
                            .stroke(palette.selectedRowBorder, lineWidth: 1)
                    }
                    .shadow(
                        color: palette.statusColor(snapshot.status).opacity(0.10),
                        radius: 8,
                        y: 3
                    )
                    .matchedGeometryEffect(
                        id: "selected-provider-row",
                        in: selectionNamespace
                    )
            }

            HStack(spacing: 9) {
                ProviderMark(name: snapshot.displayName, palette: palette, size: 28)
                    .scaleEffect(isSelected ? 1.04 : 1)

                VStack(alignment: .leading, spacing: 1) {
                    Text(snapshot.displayName)
                        .font(.system(size: 11.5, weight: .semibold))
                        .foregroundStyle(palette.primaryText)

                    Text(snapshot.accountName)
                        .font(.system(size: 9.5, weight: .medium))
                        .foregroundStyle(palette.tertiaryText)
                }

                Spacer()

                Text(metric)
                    .font(.system(size: 11.5, weight: .medium))
                    .fontWidth(.condensed)
                    .monospacedDigit()
                    .foregroundStyle(palette.primaryText)

                Circle()
                    .fill(palette.statusColor(snapshot.status))
                    .frame(width: 6, height: 6)
                    .accessibilityLabel(statusText(snapshot.status))
            }
            .padding(.horizontal, 9)
            .offset(x: isSelected ? 1 : 0)
        }
        .frame(height: 42)
        .contentShape(Rectangle())
    }

    private var metric: String {
        if let balance = snapshot.balance {
            return "\(balance.currencyCode) \(balance.amount)"
        }
        if let ratio = snapshot.quotaWindows.first?.remainingRatio {
            return percentage(ratio)
        }
        return "暂无"
    }
}

private struct ProviderMark: View {
    let name: String
    let palette: DeckPalette
    let size: CGFloat

    var body: some View {
        Text(String(name.prefix(1)).uppercased())
            .font(.system(size: size * 0.42, weight: .semibold))
            .frame(width: size, height: size)
            .background(palette.markFill, in: RoundedRectangle(cornerRadius: size * 0.32))
            .overlay {
                RoundedRectangle(cornerRadius: size * 0.32)
                    .stroke(palette.markBorder, lineWidth: 1)
            }
            .foregroundStyle(palette.markText)
    }
}

private struct StatusIndicator: View {
    let status: ProviderStatus
    let palette: DeckPalette

    var body: some View {
        Circle()
            .fill(palette.controlFill)
            .frame(width: 24, height: 24)
            .overlay {
                Circle()
                    .fill(palette.statusColor(status))
                    .frame(width: 7, height: 7)
            }
            .overlay {
                Circle()
                    .stroke(palette.controlBorder, lineWidth: 1)
            }
            .accessibilityLabel(statusText(status))
    }
}

private struct PanelBackground: View {
    let palette: DeckPalette

    var body: some View {
        ZStack {
            palette.panelBase

            LinearGradient(
                colors: [
                    Color.white.opacity(palette.isDark ? 0.025 : 0.26),
                    palette.panelTint.opacity(palette.isDark ? 0.10 : 0.18)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
}

private struct DeckPalette {
    let isDark: Bool

    init(colorScheme: ColorScheme) {
        isDark = colorScheme == .dark
    }

    var panelBase: Color { isDark ? Color(hex: 0x171D26) : Color(hex: 0xEEF3F7) }
    var panelTint: Color { isDark ? Color(hex: 0x34445A) : Color(hex: 0xD5E2EE) }
    var heroBase: Color { isDark ? Color(hex: 0x222B36) : Color(hex: 0xE7EDF2) }
    var heroCool: Color { isDark ? Color(hex: 0x30445F) : Color(hex: 0xC5DDF0) }
    var primaryText: Color { isDark ? Color(hex: 0xF0F3F6) : Color(hex: 0x171A20) }
    var secondaryText: Color { isDark ? Color(hex: 0xBBC5D0) : Color(hex: 0x4D5967) }
    var tertiaryText: Color { isDark ? Color(hex: 0x909CAA) : Color(hex: 0x667382) }
    var healthy: Color { isDark ? Color(hex: 0x76C9A0) : Color(hex: 0x61B68B) }
    var warning: Color { isDark ? Color(hex: 0xE0B968) : Color(hex: 0xC99642) }
    var critical: Color { isDark ? Color(hex: 0xEC8B77) : Color(hex: 0xDA745E) }
    var unavailable: Color { isDark ? Color(hex: 0x919CAA) : Color(hex: 0x8A94A1) }
    var outerBorder: Color { Color.white.opacity(isDark ? 0.10 : 0.62) }
    var heroBorder: Color { Color.white.opacity(isDark ? 0.09 : 0.36) }
    var controlFill: Color { Color.white.opacity(isDark ? 0.07 : 0.28) }
    var controlBorder: Color { Color.white.opacity(isDark ? 0.10 : 0.48) }
    var selectedRow: Color { Color.white.opacity(isDark ? 0.055 : 0.40) }
    var selectedRowBorder: Color { Color.white.opacity(isDark ? 0.07 : 0.46) }
    var markFill: Color { Color.white.opacity(isDark ? 0.07 : 0.34) }
    var markBorder: Color { Color.white.opacity(isDark ? 0.08 : 0.50) }
    var markText: Color { isDark ? Color(hex: 0xDDE6EF) : Color(hex: 0x33465C) }
    var progressTrack: Color { Color.white.opacity(isDark ? 0.10 : 0.30) }
    var weeklyFill: Color { Color.white.opacity(isDark ? 0.055 : 0.18) }
    var weeklyBorder: Color { Color.white.opacity(isDark ? 0.085 : 0.30) }

    func statusColor(_ status: ProviderStatus) -> Color {
        switch status {
        case .healthy: healthy
        case .warning: warning
        case .critical: critical
        case .unavailable: unavailable
        }
    }

    func heroGlow(_ status: ProviderStatus) -> Color {
        switch status {
        case .healthy:
            return isDark ? Color(hex: 0x33584A) : Color(hex: 0xD9EEE3)
        case .warning:
            return isDark ? Color(hex: 0x5B4D2F) : Color(hex: 0xF5E7B9)
        case .critical:
            return isDark ? Color(hex: 0x5C403A) : Color(hex: 0xF1C9B3)
        case .unavailable:
            return isDark ? Color(hex: 0x3C4551) : Color(hex: 0xD9DEE5)
        }
    }

    func heroWarm(_ status: ProviderStatus) -> Color {
        switch status {
        case .healthy:
            return isDark ? Color(hex: 0x344B66) : Color(hex: 0xBFD7EB)
        case .warning:
            return isDark ? Color(hex: 0x65543A) : Color(hex: 0xE7D39F)
        case .critical:
            return isDark ? Color(hex: 0x6A453C) : Color(hex: 0xE6A98E)
        case .unavailable:
            return isDark ? Color(hex: 0x394452) : Color(hex: 0xCCD4DE)
        }
    }

    func heroAmbient(_ status: ProviderStatus) -> Color {
        switch status {
        case .healthy:
            return isDark ? Color(hex: 0x345D55) : Color(hex: 0xB8DFD5)
        case .warning:
            return isDark ? Color(hex: 0x625431) : Color(hex: 0xE9D69D)
        case .critical:
            return isDark ? Color(hex: 0x68483F) : Color(hex: 0xE8B69E)
        case .unavailable:
            return isDark ? Color(hex: 0x414C59) : Color(hex: 0xC8D2DE)
        }
    }

    func progressColors(_ status: ProviderStatus) -> [Color] {
        switch status {
        case .healthy:
            return [
                isDark ? Color(hex: 0x6BA5E8) : Color(hex: 0x4B86D8),
                isDark ? Color(hex: 0x91C5F0) : Color(hex: 0x9AC1EB)
            ]
        case .warning:
            return [
                isDark ? Color(hex: 0xD5A95E) : Color(hex: 0xC8923D),
                isDark ? Color(hex: 0xE8CA88) : Color(hex: 0xE7C47C)
            ]
        case .critical:
            return [
                isDark ? Color(hex: 0xED826D) : Color(hex: 0xE1745C),
                isDark ? Color(hex: 0xF3BE78) : Color(hex: 0xEDB96D)
            ]
        case .unavailable:
            return [unavailable, unavailable.opacity(0.65)]
        }
    }
}

private extension Color {
    init(hex: UInt32) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255
        )
    }
}

private func statusText(_ status: ProviderStatus) -> String {
    switch status {
    case .healthy: "正常"
    case .warning: "注意"
    case .critical: "紧急"
    case .unavailable: "不可用"
    }
}

func resetTimestamp(
    _ date: Date?,
    timeZone: TimeZone = .autoupdatingCurrent
) -> String {
    guard let date else {
        return "时间未知"
    }

    return formattedDate(date, dateFormat: "M月d日 HH:mm", timeZone: timeZone)
}

func resetDate(
    _ date: Date?,
    timeZone: TimeZone = .autoupdatingCurrent
) -> String {
    guard let date else {
        return "日期未知"
    }

    return formattedDate(date, dateFormat: "M月d日", timeZone: timeZone)
}

private func formattedDate(
    _ date: Date,
    dateFormat: String,
    timeZone: TimeZone
) -> String {
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "zh_CN")
    formatter.calendar = Calendar(identifier: .gregorian)
    formatter.timeZone = timeZone
    formatter.dateFormat = dateFormat
    return formatter.string(from: date)
}

private func decimalDouble(_ value: Decimal) -> Double {
    NSDecimalNumber(decimal: value).doubleValue
}

private func percentage(_ value: Decimal) -> String {
    "\(Int((decimalDouble(value) * 100).rounded()))%"
}
