import AppKit
import SwiftUI
import UniformTypeIdentifiers
import MiracleDeckCore

struct DeckAnimationsEnabledKey: EnvironmentKey {
    static let defaultValue = true
}

enum PanelTone: String {
    case glacier
    case fog
    case celadon
    case violetSmoke
    case crystalGlass
    case pearlGlass
    case seaGlass
    case moonGlass
}

enum MonitorDisplayMode: String {
    case arrangement
    case card
}

struct PanelToneKey: EnvironmentKey {
    static let defaultValue = PanelTone.pearlGlass
}

extension EnvironmentValues {
    var deckAnimationsEnabled: Bool {
        get { self[DeckAnimationsEnabledKey.self] }
        set { self[DeckAnimationsEnabledKey.self] = newValue }
    }

    var panelTone: PanelTone {
        get { self[PanelToneKey.self] }
        set { self[PanelToneKey.self] = newValue }
    }
}

public struct MonitorPanelView: View {
    public static let preferredSize = DeckLayoutPreset.default.panelSize

    private let snapshots: [ProviderSnapshot]
    @ObservedObject private var layoutStore: DeckLayoutStore
    @State private var orderedIDs: [UUID]
    @State private var selectedID: UUID?
    @State private var displayMode: MonitorDisplayMode
    @State private var draggedID: UUID?
    @Namespace private var selectionNamespace
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.panelTone) private var panelTone
    @Environment(\.deckAnimationsEnabled) private var animationsEnabled

    public init(
        snapshots: [ProviderSnapshot],
        layoutStore: DeckLayoutStore = .shared
    ) {
        self.init(
            snapshots: snapshots,
            initialMode: .arrangement,
            layoutStore: layoutStore
        )
    }

    init(
        snapshots: [ProviderSnapshot],
        initialMode: MonitorDisplayMode,
        layoutStore: DeckLayoutStore = .shared
    ) {
        self.snapshots = snapshots
        self._layoutStore = ObservedObject(wrappedValue: layoutStore)
        self._orderedIDs = State(initialValue: snapshots.map(\.id))
        self._selectedID = State(initialValue: snapshots.first?.id)
        self._displayMode = State(initialValue: initialMode)
    }

    public var body: some View {
        let palette = DeckPalette(colorScheme: colorScheme, panelTone: panelTone)
        let layout = layoutStore.preset

        ZStack(alignment: .top) {
            PanelBackground(palette: palette)

            arrangementChrome(palette: palette, layout: layout)
                .opacity(displayMode == .arrangement ? 1 : 0)
                .allowsHitTesting(displayMode == .arrangement)
                .animation(chromeAnimation, value: displayMode)

            if let selectedSnapshot {
                heroSurface(
                    snapshot: selectedSnapshot,
                    palette: palette,
                    layout: layout
                )
            }
        }
        .frame(
            width: layout.panelWidth,
            height: layout.panelHeight,
            alignment: .top
        )
        .background(PanelBackground(palette: palette))
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(palette.outerBorder, lineWidth: 1)
        }
        .onChange(of: snapshots.map(\.id)) { _, newIDs in
            reconcileOrder(with: newIDs)
        }
    }

    private var selectedSnapshot: ProviderSnapshot? {
        snapshots.first(where: { $0.id == selectedID }) ?? snapshots.first
    }

    private var orderedSnapshots: [ProviderSnapshot] {
        let byID = Dictionary(
            uniqueKeysWithValues: snapshots.map { ($0.id, $0) }
        )
        let knownIDs = Set(orderedIDs)
        let ordered = orderedIDs.compactMap { byID[$0] }
        return ordered + snapshots.filter { !knownIDs.contains($0.id) }
    }

    private var selectionAnimation: Animation {
        reduceMotion || !animationsEnabled
            ? .linear(duration: 0.01)
            : .spring(response: 0.34, dampingFraction: 0.86)
    }

    private var modeAnimation: Animation {
        reduceMotion || !animationsEnabled
            ? .linear(duration: 0.01)
            : .timingCurve(0.18, 0.78, 0.22, 1, duration: 0.42)
    }

    private var chromeAnimation: Animation? {
        guard !reduceMotion, animationsEnabled else {
            return nil
        }

        return modeAnimation
    }

    private func arrangementChrome(
        palette: DeckPalette,
        layout: DeckLayoutPreset
    ) -> some View {
        VStack(spacing: layout.arrangementSpacing) {
            header(palette: palette)

            Color.clear
                .frame(height: layout.compactHeroHeight)
                .accessibilityHidden(true)

            providerList(palette: palette, layout: layout)
            footer(palette: palette)
        }
        .padding(layout.arrangementInset)
    }

    private func heroSurface(
        snapshot: ProviderSnapshot,
        palette: DeckPalette,
        layout: DeckLayoutPreset
    ) -> some View {
        ProviderHeroCard(
            snapshot: snapshot,
            palette: palette,
            presentation: displayMode == .card ? .expanded : .compact,
            layout: layout
        )
        .frame(
            height: displayMode == .card
                ? layout.panelHeight
                : layout.compactHeroHeight
        )
        .clipShape(
            RoundedRectangle(
                cornerRadius: displayMode == .card ? 22 : 26,
                style: .continuous
            )
        )
        .overlay {
            RoundedRectangle(
                cornerRadius: displayMode == .card ? 22 : 26,
                style: .continuous
            )
            .stroke(palette.heroBorder, lineWidth: 1)
        }
        .background {
            HeroAmbientGlow(
                status: snapshot.status,
                palette: palette
            )
            .opacity(displayMode == .arrangement ? 1 : 0)
        }
        .shadow(
            color: palette.heroAmbient(snapshot.status)
                .opacity(
                    displayMode == .arrangement
                        ? (palette.isDark ? 0.18 : 0.30)
                        : 0
                ),
            radius: 22,
            y: 7
        )
        .padding(
            .horizontal,
            displayMode == .arrangement ? layout.arrangementInset : 0
        )
        .offset(y: displayMode == .arrangement ? layout.heroOffsetY : 0)
        .overlay {
            if displayMode == .card {
                CardModeGestureSurface(
                    onNavigate: selectRelativeAccount,
                    onCollapse: exitCardMode
                )
                .padding(.top, 58)
            }
        }
        .overlay(alignment: .topTrailing) {
            HStack(spacing: 6) {
                HeaderButton(
                    systemName: "arrow.clockwise",
                    help: "刷新",
                    palette: palette
                )

                SettingsHeaderButton(palette: palette)

                StatusIndicator(status: snapshot.status, palette: palette)
            }
            .padding(.top, 20)
            .padding(.trailing, 20)
            .opacity(displayMode == .card ? 1 : 0)
            .allowsHitTesting(displayMode == .card)
            .animation(cardControlsAnimation, value: displayMode)
        }
        .contentShape(
            RoundedRectangle(
                cornerRadius: displayMode == .card ? 22 : 26,
                style: .continuous
            )
        )
        .zIndex(1)
        .onTapGesture(count: 2) {
            if displayMode == .arrangement {
                enterCardMode()
            }
        }
        .help(displayMode == .card ? "双击返回" : "双击展开")
        .accessibilityHint(
            displayMode == .card
                ? "上下或左右滑动切换账户，双击返回"
                : "双击展开卡片"
        )
    }

    private var cardControlsAnimation: Animation? {
        guard !reduceMotion, animationsEnabled else {
            return nil
        }

        return modeAnimation
    }

    private func enterCardMode() {
        guard selectedSnapshot != nil else {
            return
        }

        withAnimation(modeAnimation) {
            displayMode = .card
        }
    }

    private func exitCardMode() {
        withAnimation(modeAnimation) {
            displayMode = .arrangement
        }
    }

    private func selectRelativeAccount(_ offset: Int) {
        guard let nextID = relativeProviderID(
            in: orderedIDs,
            from: selectedID,
            offset: offset
        ) else {
            return
        }

        withAnimation(selectionAnimation) {
            selectedID = nextID
        }
    }

    private func reconcileOrder(with snapshotIDs: [UUID]) {
        let available = Set(snapshotIDs)
        let retained = orderedIDs.filter(available.contains)
        let retainedSet = Set(retained)
        orderedIDs = retained + snapshotIDs.filter { !retainedSet.contains($0) }

        if let selectedID, available.contains(selectedID) {
            return
        }

        selectedID = orderedIDs.first
        if selectedID == nil {
            displayMode = .arrangement
        }
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

            SettingsHeaderButton(palette: palette)
        }
        .frame(height: 26)
    }

    private func providerList(
        palette: DeckPalette,
        layout: DeckLayoutPreset
    ) -> some View {
        ScrollViewReader { proxy in
            ScrollView(.vertical) {
                LazyVStack(spacing: 3) {
                    ForEach(orderedSnapshots) { snapshot in
                        Button {
                            withAnimation(selectionAnimation) {
                                selectedID = snapshot.id
                            }
                        } label: {
                            ProviderCompactRow(
                                snapshot: snapshot,
                                isSelected: selectedID == snapshot.id,
                                palette: palette,
                                selectionNamespace: selectionNamespace,
                                metricFontSize: layout.listMetricFontSize
                            )
                        }
                        .buttonStyle(.plain)
                        .id(snapshot.id)
                        .onDrag {
                            draggedID = snapshot.id
                            return NSItemProvider(
                                object: snapshot.id.uuidString as NSString
                            )
                        }
                        .onDrop(
                            of: [UTType.text],
                            delegate: ProviderRowDropDelegate(
                                destinationID: snapshot.id,
                                orderedIDs: $orderedIDs,
                                draggedID: $draggedID,
                                animationsEnabled: animationsEnabled && !reduceMotion
                            )
                        )
                    }
                }
            }
            .scrollIndicators(.hidden)
            .frame(height: providerListHeight)
            .onAppear {
                if let selectedID {
                    proxy.scrollTo(selectedID, anchor: .center)
                }
            }
            .onChange(of: selectedID) { _, newID in
                guard let newID else {
                    return
                }

                withAnimation(selectionAnimation) {
                    proxy.scrollTo(newID, anchor: .center)
                }
            }
        }
    }

    private var providerListHeight: CGFloat {
        providerListViewportHeight(accountCount: orderedSnapshots.count)
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

private struct SettingsHeaderButton: View {
    let palette: DeckPalette

    var body: some View {
        SettingsLink {
            Image(systemName: "gearshape")
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
        .contentShape(Circle())
        .help("设置")
    }
}

private enum HeroPresentation {
    case compact
    case expanded

    var isExpanded: Bool {
        self == .expanded
    }
}

private struct ProviderHeroCard: View {
    let snapshot: ProviderSnapshot
    let palette: DeckPalette
    let presentation: HeroPresentation
    let layout: DeckLayoutPreset
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.deckAnimationsEnabled) private var animationsEnabled

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .topLeading) {
                HeroBackground(
                    status: snapshot.status,
                    palette: palette,
                    canvasSize: CGSize(
                        width: layout.panelWidth,
                        height: layout.panelHeight
                    ),
                    gradientExtent: CGSize(
                        width: layout.panelWidth
                            - (layout.arrangementInset * 2),
                        height: layout.compactHeroHeight
                    )
                )
                    .frame(
                        width: layout.panelWidth,
                        height: layout.panelHeight,
                        alignment: .topLeading
                    )

                sharedContent(in: geometry.size)

                if presentation.isExpanded {
                    expandedDetails(in: geometry.size)
                        .transition(supplementaryTransition)
                } else {
                    compactDetails(in: geometry.size)
                        .transition(supplementaryTransition)
                }
            }
            .frame(
                width: geometry.size.width,
                height: geometry.size.height,
                alignment: .topLeading
            )
            .animation(contentModeAnimation, value: presentation)
        }
    }

    private func sharedContent(in size: CGSize) -> some View {
        let expanded = presentation.isExpanded
        let expandedPrimary = snapshot.balance == nil
            ? layout.expandedQuotaPrimary
            : layout.expandedBalancePrimary
        let compactPrimary = snapshot.balance == nil
            ? layout.compactQuotaPrimary
            : layout.compactBalancePrimary
        let identityWidth = expanded
            ? max(128, size.width - 124)
            : max(160, size.width - 60)

        return ZStack(alignment: .topLeading) {
            identityHeader(
                titleSize: 13,
                labelSize: 12,
                showsStatus: false
            )
            .frame(width: identityWidth, alignment: .topLeading)
            .scaleEffect(
                expanded ? 1 : 0.90,
                anchor: .topLeading
            )
            .offset(
                x: expanded
                    ? layout.expandedIdentity.x
                    : layout.compactIdentity.x,
                y: expanded
                    ? layout.expandedIdentity.y
                    : layout.compactIdentity.y
            )

            heroPrimaryMetric
                .scaleEffect(
                    expanded ? 1 : compactPrimaryScale,
                    anchor: .topLeading
                )
                .offset(
                    x: expanded
                        ? expandedPrimary.x
                        : compactPrimary.x,
                    y: expanded
                        ? expandedPrimary.y
                        : compactPrimary.y
                )

            if let primaryQuota,
               let remainingRatio = primaryQuota.remainingRatio {
                primaryQuotaProgress(
                    quota: primaryQuota,
                    remainingRatio: remainingRatio
                )
                .frame(
                    width: expanded
                        ? size.width - layout.expandedProgress.x - 20
                        : compactProgressWidth(in: size)
                )
                .offset(
                    x: expanded
                        ? layout.expandedProgress.x
                        : layout.compactProgress.x,
                    y: expanded
                        ? layout.expandedProgress.y
                        : layout.compactProgress.y
                )
            }
        }
        .frame(
            width: size.width,
            height: size.height,
            alignment: .topLeading
        )
        .foregroundStyle(palette.primaryText)
        .animation(
            reduceMotion || !animationsEnabled
                ? nil
                : contentModeAnimation,
            value: presentation
        )
    }

    private func compactDetails(in size: CGSize) -> some View {
        return ZStack(alignment: .topLeading) {
            CompactStatusDot(
                status: snapshot.status,
                palette: palette,
                size: layout.compactStatusSize
            )
            .offset(
                x: layout.compactStatus.x,
                y: layout.compactStatus.y
            )

            if snapshot.balance != nil {
                Text(shortUpdateTimestamp(snapshot.fetchedAt))
                    .font(.system(size: 9.5, weight: .medium))
                    .foregroundStyle(palette.tertiaryText)
                    .offset(
                        x: layout.compactFooter.x,
                        y: layout.compactFooter.y
                    )

                ProviderLogo(
                    snapshot: snapshot,
                    palette: palette,
                    size: layout.compactLogoSize,
                    style: .card
                )
                .offset(
                    x: layout.compactLogo.x,
                    y: layout.compactLogo.y
                )
            }
        }
        .frame(
            width: size.width,
            height: size.height,
            alignment: .topLeading
        )
        .foregroundStyle(palette.primaryText)
    }

    private func expandedDetails(in size: CGSize) -> some View {
        let insightPoint = snapshot.balance == nil
            ? layout.expandedInsights
            : layout.expandedBalanceInsights

        return ZStack(alignment: .topLeading) {
            expandedInsightRow
                .frame(
                    width: size.width
                        - insightPoint.x
                        - 20
                )
                .offset(
                    x: insightPoint.x,
                    y: insightPoint.y
                )

            expandedSecondaryMetric
                .frame(
                    width: max(
                        150,
                        layout.expandedLogo.x
                            - layout.expandedSecondary.x
                            - 16
                    ),
                    height: 90,
                    alignment: .bottomLeading
                )
                .offset(
                    x: layout.expandedSecondary.x,
                    y: layout.expandedSecondary.y
                )

            ProviderLogo(
                snapshot: snapshot,
                palette: palette,
                size: layout.expandedLogoSize,
                style: .card
            )
            .offset(
                x: layout.expandedLogo.x,
                y: layout.expandedLogo.y
            )
        }
        .frame(
            width: size.width,
            height: size.height,
            alignment: .topLeading
        )
        .foregroundStyle(palette.primaryText)
    }

    private var supplementaryTransition: AnyTransition {
        guard !reduceMotion, animationsEnabled else {
            return .identity
        }

        return .opacity.animation(contentModeAnimation)
    }

    private var contentModeAnimation: Animation {
        .timingCurve(0.18, 0.78, 0.22, 1, duration: 0.42)
    }

    @ViewBuilder
    private var heroPrimaryMetric: some View {
        if let balance = snapshot.balance {
            MoneyMetric(
                money: balance,
                numberSize: 58,
                currencySize: 21,
                spacing: 10,
                weight: .medium
            )
        } else if let remainingRatio = primaryQuota?.remainingRatio {
            PercentageMetric(
                ratio: remainingRatio,
                numberSize: 72,
                symbolSize: 25,
                symbolBottomPadding: 7
            )
        } else {
            Text("暂无")
                .font(.system(size: 58, weight: .medium))
        }
    }

    private func primaryQuotaProgress(
        quota: QuotaWindow,
        remainingRatio: Decimal
    ) -> some View {
        let recoveryText = durationUntilReset(
            quota.resetsAt,
            from: snapshot.fetchedAt
        )

        return VStack(alignment: .leading, spacing: 6) {
            QuotaProgressBar(
                value: decimalDouble(remainingRatio),
                status: snapshot.status,
                palette: palette
            )

            HStack(alignment: .top) {
                Text(quota.title)
                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text(resetTimestamp(quota.resetsAt))

                    if presentation.isExpanded {
                        Text("距离恢复 · \(recoveryText)")
                        .font(.system(size: 9.5, weight: .medium))
                        .foregroundStyle(palette.tertiaryText.opacity(0.84))
                    }
                }
            }
            .font(
                .system(
                    size: 10.5,
                    weight: .medium
                )
            )
            .foregroundStyle(palette.tertiaryText)
        }
    }

    private var compactPrimaryScale: CGFloat {
        snapshot.balance == nil ? 0.64 : 0.66
    }

    private func compactProgressWidth(in size: CGSize) -> CGFloat {
        return max(
            120,
            size.width
                - layout.compactProgress.x
                - 15
        )
    }

    @ViewBuilder
    private var expandedSecondaryMetric: some View {
        if let weeklyQuota,
           let weeklyRemainingRatio = weeklyQuota.remainingRatio {
            VStack(alignment: .leading, spacing: 4) {
                Text("本周 · \(resetDate(weeklyQuota.resetsAt))")
                    .font(.system(size: 12.5, weight: .medium))
                    .foregroundStyle(palette.tertiaryText)

                PercentageMetric(
                    ratio: weeklyRemainingRatio,
                    numberSize: 34,
                    symbolSize: 15,
                    symbolBottomPadding: 3
                )

                Text(resetCountText(weeklyQuota.resetCount))
                    .font(.system(size: 10, weight: .medium))
                    .lineLimit(1)
                    .foregroundStyle(palette.tertiaryText)

                Text(updateTimestamp(snapshot.fetchedAt))
                    .font(.system(size: 10, weight: .medium))
                    .lineLimit(1)
                    .foregroundStyle(palette.tertiaryText)
            }
        } else {
            VStack(alignment: .leading, spacing: 4) {
                Text(recentSpendLabel)
                    .font(.system(size: 12.5, weight: .medium))
                    .foregroundStyle(palette.tertiaryText)

                if let spend = recentSpendSummary?.spend {
                    MoneyMetric(
                        money: spend,
                        numberSize: 34,
                        currencySize: 13,
                        spacing: 6,
                        weight: .medium
                    )
                } else {
                    Text("暂无数据")
                        .font(.system(size: 24, weight: .medium))
                }

                Text(recentSpendMetadata)
                    .font(.system(size: 10, weight: .medium))
                    .lineLimit(1)
                    .foregroundStyle(palette.tertiaryText)
            }
        }
    }

    @ViewBuilder
    private var expandedInsightRow: some View {
        if let summary = recentSpendSummary {
            CardInsightRow(
                items: [
                    CardInsight(
                        label: "请求数",
                        value: summary.requestCount.map {
                            compactCount($0)
                        } ?? "—"
                    ),
                    CardInsight(
                        label: "Token",
                        value: compactTokenCount(summary)
                    ),
                    CardInsight(
                        label: "单次均价",
                        value: averageRequestCost(summary)
                    )
                ],
                palette: palette
            )
        } else {
            EmptyView()
        }
    }

    private func resetCountText(_ resetCount: Int?) -> String {
        guard let resetCount else {
            return "重置次数未知"
        }
        return "已重置 \(resetCount) 次"
    }

    private func identityHeader(
        titleSize: CGFloat,
        labelSize: CGFloat,
        showsStatus: Bool = true
    ) -> some View {
        HStack(alignment: .top, spacing: 8) {
            VStack(alignment: .leading, spacing: 3) {
                Text(snapshot.displayName.uppercased())
                    .font(.system(size: titleSize, weight: .semibold))
                    .tracking(1.25)
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)
                    .allowsTightening(true)

                Text("\(snapshot.accountName) · \(primaryLabel)")
                    .font(.system(size: labelSize, weight: .medium))
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)
            }

            Spacer()

            if showsStatus {
                StatusIndicator(status: snapshot.status, palette: palette)
            }
        }
    }

    private var primaryLabel: String {
        snapshot.balance == nil ? "套餐剩余额度" : "可用余额"
    }

    private var primaryQuota: QuotaWindow? {
        snapshot.quotaWindows.first
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

    private var recentSpendSummary: UsageSummary? {
        snapshot.usage
            .filter { $0.spend != nil }
            .max { $0.period.end < $1.period.end }
    }

    private var recentSpendLabel: String {
        guard let summary = recentSpendSummary else {
            return "最近花费"
        }

        let days = max(1, Int(ceil(summary.period.duration / 86_400)))
        return days == 1 ? "今日花费" : "近 \(days) 天花费"
    }

    private var recentSpendMetadata: String {
        updateTimestamp(snapshot.fetchedAt)
    }

}

private struct PercentageMetric: View {
    let ratio: Decimal
    let numberSize: CGFloat
    let symbolSize: CGFloat
    let symbolBottomPadding: CGFloat

    var body: some View {
        HStack(alignment: .bottom, spacing: 5) {
            Text(percentageNumber(ratio))
                .font(.system(size: numberSize, weight: .medium))
                .monospacedDigit()
                .tracking(-1)
                .contentTransition(.numericText())

            Text("%")
                .font(.system(size: symbolSize, weight: .semibold))
                .padding(.bottom, symbolBottomPadding)
        }
        .fixedSize()
    }
}

private struct MoneyMetric: View {
    let money: Money
    let numberSize: CGFloat
    let currencySize: CGFloat
    let spacing: CGFloat
    let weight: Font.Weight

    var body: some View {
        HStack(alignment: .bottom, spacing: spacing) {
            Text(moneyAmount(money.amount))
                .font(.system(size: numberSize, weight: weight))
                .monospacedDigit()
                .tracking(-0.6)
                .contentTransition(.numericText())

            Text(money.currencyCode)
                .font(.system(size: currencySize, weight: .semibold))
                .tracking(0.7)
                .padding(.bottom, max(3, numberSize * 0.13))
        }
        .fixedSize()
    }
}

private struct CardInsight {
    let label: String
    let value: String
}

private struct CardInsightRow: View {
    let items: [CardInsight]
    let palette: DeckPalette

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                VStack(alignment: .leading, spacing: 5) {
                    Text(item.label)
                        .font(.system(size: 9.5, weight: .medium))
                        .foregroundStyle(palette.tertiaryText)

                    Text(item.value)
                        .font(.system(size: 14, weight: .semibold))
                        .monospacedDigit()
                        .lineLimit(1)
                        .minimumScaleFactor(0.82)
                        .foregroundStyle(palette.primaryText)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                if index < items.count - 1 {
                    Rectangle()
                        .fill(palette.heroBorder.opacity(0.72))
                        .frame(width: 1, height: 31)
                        .padding(.horizontal, 13)
                }
            }
        }
        .frame(maxWidth: .infinity)
    }
}

private struct HeroBackground: View {
    let status: ProviderStatus
    let palette: DeckPalette
    let canvasSize: CGSize
    let gradientExtent: CGSize

    var body: some View {
        ZStack {
            palette.heroBase

            RadialGradient(
                colors: [palette.heroCool.opacity(0.92), .clear],
                center: UnitPoint(
                    x: gradientExtent.width / canvasSize.width,
                    y: 0
                ),
                startRadius: 0,
                endRadius: 180
            )

            RadialGradient(
                colors: [palette.heroGlow(status).opacity(0.82), .clear],
                center: UnitPoint(
                    x: 0,
                    y: gradientExtent.height / canvasSize.height
                ),
                startRadius: 0,
                endRadius: 190
            )

            LinearGradient(
                colors: [
                    Color.white.opacity(palette.isDark ? 0.02 : 0.18),
                    palette.heroWarm(status).opacity(palette.isDark ? 0.22 : 0.32)
                ],
                startPoint: .topLeading,
                endPoint: UnitPoint(
                    x: gradientExtent.width / canvasSize.width,
                    y: gradientExtent.height / canvasSize.height
                )
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
                .fill(
                    palette.heroAmbient(status)
                        .opacity(palette.isDark ? 0.22 : 0.36)
                )
                .blur(radius: 28)
                .scaleEffect(x: 1.045, y: 0.90)
                .offset(y: 8)

            RadialGradient(
                colors: [
                    palette.heroCool.opacity(palette.isDark ? 0.16 : 0.28),
                    .clear
                ],
                center: .topTrailing,
                startRadius: 10,
                endRadius: 210
            )
            .blur(radius: 18)
            .padding(-12)
        }
        .allowsHitTesting(false)
    }
}

private struct QuotaProgressBar: View {
    let value: Double
    let status: ProviderStatus
    let palette: DeckPalette
    @State private var displayedValue: Double
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.deckAnimationsEnabled) private var animationsEnabled

    init(
        value: Double,
        status: ProviderStatus,
        palette: DeckPalette
    ) {
        self.value = value
        self.status = status
        self.palette = palette
        self._displayedValue = State(initialValue: value)
    }

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
    let metricFontSize: CGFloat

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
                ProviderLogo(
                    snapshot: snapshot,
                    palette: palette,
                    size: 18,
                    style: .list
                )
                    .scaleEffect(isSelected ? 1.04 : 1)

                VStack(alignment: .leading, spacing: 1) {
                    Text(snapshot.displayName)
                        .font(.system(size: 10.5, weight: .semibold))
                        .foregroundStyle(palette.primaryText)

                    Text(snapshot.accountName)
                        .font(.system(size: 8.5, weight: .medium))
                        .foregroundStyle(palette.tertiaryText)
                }

                Spacer()

                Text(metric)
                    .font(.system(size: metricFontSize, weight: .semibold))
                    .fontWidth(.condensed)
                    .monospacedDigit()
                    .foregroundStyle(palette.primaryText)

                Circle()
                    .fill(palette.statusColor(snapshot.status))
                    .frame(width: 6, height: 6)
                    .accessibilityLabel(statusText(snapshot.status))
            }
            .padding(.horizontal, 8)
            .offset(x: isSelected ? 1 : 0)
        }
        .frame(height: 34)
        .contentShape(Rectangle())
    }

    private var metric: String {
        if let balance = snapshot.balance {
            return "\(balance.amount) \(balance.currencyCode)"
        }
        if let ratio = snapshot.quotaWindows.first?.remainingRatio {
            return percentage(ratio)
        }
        return "暂无"
    }
}

private struct ProviderRowDropDelegate: DropDelegate {
    let destinationID: UUID
    @Binding var orderedIDs: [UUID]
    @Binding var draggedID: UUID?
    let animationsEnabled: Bool

    func dropEntered(info: DropInfo) {
        guard let draggedID,
              draggedID != destinationID else {
            return
        }

        let reordered = reorderedProviderIDs(
            orderedIDs,
            moving: draggedID,
            to: destinationID
        )
        guard reordered != orderedIDs else {
            return
        }

        if animationsEnabled {
            withAnimation(.spring(response: 0.28, dampingFraction: 0.88)) {
                orderedIDs = reordered
            }
        } else {
            orderedIDs = reordered
        }
    }

    func dropUpdated(info: DropInfo) -> DropProposal? {
        DropProposal(operation: .move)
    }

    func performDrop(info: DropInfo) -> Bool {
        draggedID = nil
        return true
    }
}

private struct CardModeGestureSurface: NSViewRepresentable {
    let onNavigate: (Int) -> Void
    let onCollapse: () -> Void

    func makeNSView(context: Context) -> CardGestureView {
        let view = CardGestureView()
        view.onNavigate = onNavigate
        view.onCollapse = onCollapse
        return view
    }

    func updateNSView(_ nsView: CardGestureView, context: Context) {
        nsView.onNavigate = onNavigate
        nsView.onCollapse = onCollapse
    }
}

struct CardScrollGestureGate {
    private var accumulated = CGSize.zero
    private var didNavigateInGesture = false
    private var lastNavigationTime = -Double.infinity

    mutating func beginGesture() {
        accumulated = .zero
        didNavigateInGesture = false
    }

    mutating func endGesture() {
        accumulated = .zero
    }

    mutating func consume(
        delta: CGSize,
        hasPreciseDeltas: Bool,
        isMomentum: Bool,
        phaseIsEmpty: Bool,
        now: TimeInterval
    ) -> Int? {
        guard !isMomentum else {
            return nil
        }

        accumulated.width += delta.width
        accumulated.height += delta.height

        guard !didNavigateInGesture else {
            return nil
        }

        let dominant = max(abs(accumulated.width), abs(accumulated.height))
        let threshold: CGFloat = hasPreciseDeltas ? 72 : 8
        guard dominant >= threshold,
              now - lastNavigationTime > 0.55 else {
            return nil
        }

        let offset = cardNavigationOffset(
            horizontal: accumulated.width,
            vertical: accumulated.height,
            verticalPositiveMeansPrevious: true
        )
        lastNavigationTime = now
        didNavigateInGesture = true

        if phaseIsEmpty {
            accumulated = .zero
            didNavigateInGesture = false
        }

        return offset
    }
}

@MainActor
private final class CardGestureView: NSView {
    var onNavigate: ((Int) -> Void)?
    var onCollapse: (() -> Void)?

    private var pointerStart: NSPoint?
    private var scrollGate = CardScrollGestureGate()
    private var lastNavigationTime = 0.0

    override var acceptsFirstResponder: Bool { true }

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        installDoubleClickRecognizer()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        installDoubleClickRecognizer()
    }

    override func acceptsFirstMouse(for event: NSEvent?) -> Bool {
        true
    }

    override func mouseDown(with event: NSEvent) {
        if event.clickCount == 2 {
            pointerStart = nil
            onCollapse?()
            return
        }

        window?.makeFirstResponder(self)
        pointerStart = convert(event.locationInWindow, from: nil)
    }

    override func keyDown(with event: NSEvent) {
        if event.keyCode == 53 {
            pointerStart = nil
            onCollapse?()
            return
        }
        super.keyDown(with: event)
    }

    override func mouseUp(with event: NSEvent) {
        guard let pointerStart else {
            return
        }

        let end = convert(event.locationInWindow, from: nil)
        self.pointerStart = nil
        let delta = CGSize(
            width: end.x - pointerStart.x,
            height: end.y - pointerStart.y
        )

        navigateIfThresholdReached(
            delta: delta,
            threshold: 44,
            verticalPositiveMeansPrevious: false
        )
    }

    override func scrollWheel(with event: NSEvent) {
        if event.phase == .began {
            scrollGate.beginGesture()
        }

        if let offset = scrollGate.consume(
            delta: CGSize(
                width: event.scrollingDeltaX,
                height: event.scrollingDeltaY
            ),
            hasPreciseDeltas: event.hasPreciseScrollingDeltas,
            isMomentum: !event.momentumPhase.isEmpty,
            phaseIsEmpty: event.phase.isEmpty,
            now: Date.timeIntervalSinceReferenceDate
        ) {
            onNavigate?(offset)
        }

        if event.phase == .ended
            || event.phase == .cancelled {
            scrollGate.endGesture()
        }
    }

    @discardableResult
    private func navigateIfThresholdReached(
        delta: CGSize,
        threshold: CGFloat,
        verticalPositiveMeansPrevious: Bool
    ) -> Bool {
        let horizontal = delta.width
        let vertical = delta.height
        let dominant = abs(horizontal) > abs(vertical) ? horizontal : vertical

        guard abs(dominant) >= threshold else {
            return false
        }

        let now = Date.timeIntervalSinceReferenceDate
        guard now - lastNavigationTime > 0.55 else {
            return false
        }
        lastNavigationTime = now

        onNavigate?(
            cardNavigationOffset(
                horizontal: horizontal,
                vertical: vertical,
                verticalPositiveMeansPrevious: verticalPositiveMeansPrevious
            )
        )

        return true
    }

    private func installDoubleClickRecognizer() {
        let recognizer = NSClickGestureRecognizer(
            target: self,
            action: #selector(handleDoubleClick)
        )
        recognizer.numberOfClicksRequired = 2
        recognizer.buttonMask = 0x1
        addGestureRecognizer(recognizer)
    }

    @objc private func handleDoubleClick() {
        pointerStart = nil
        onCollapse?()
    }
}

private enum ProviderLogoStyle {
    case card
    case list
}

private struct ProviderLogo: View {
    let snapshot: ProviderSnapshot
    let palette: DeckPalette
    let size: CGFloat
    let style: ProviderLogoStyle

    var body: some View {
        Group {
            if let image = providerImage {
                Image(nsImage: image)
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
            } else {
                Image(systemName: "network")
                    .resizable()
                    .scaledToFit()
            }
        }
        .foregroundStyle(foreground)
        .frame(width: size, height: size)
        .shadow(
            color: style == .card ? Color.black.opacity(0.12) : .clear,
            radius: style == .card ? 5 : 0,
            y: style == .card ? 2 : 0
        )
        .accessibilityLabel(snapshot.displayName)
    }

    private var foreground: Color {
        switch style {
        case .card:
            Color.white.opacity(0.92)
        case .list:
            palette.listMarkText
        }
    }

    private var providerImage: NSImage? {
        guard let assetName = providerLogoAssetName(
            providerID: snapshot.providerID,
            displayName: snapshot.displayName
        ),
        let url = Bundle.module.url(
            forResource: assetName,
            withExtension: "svg"
        ),
        let image = NSImage(contentsOf: url) else {
            return nil
        }

        image.isTemplate = true
        return image
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

private struct CompactStatusDot: View {
    let status: ProviderStatus
    let palette: DeckPalette
    let size: CGFloat

    var body: some View {
        Circle()
            .fill(palette.statusColor(status))
            .frame(width: size, height: size)
            .overlay {
                Circle()
                    .stroke(Color.white.opacity(0.55), lineWidth: 1)
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
                    Color.white.opacity(
                        palette.isGlass
                            ? (palette.isDark ? 0.08 : 0.42)
                            : (palette.isDark ? 0.025 : 0.26)
                    ),
                    palette.panelTint.opacity(
                        palette.isGlass
                            ? (palette.isDark ? 0.16 : 0.18)
                            : (palette.isDark ? 0.10 : 0.18)
                    )
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            if palette.isGlass {
                RadialGradient(
                    colors: [
                        palette.glassHighlight.opacity(palette.isDark ? 0.14 : 0.50),
                        .clear
                    ],
                    center: UnitPoint(x: 0.18, y: 0.02),
                    startRadius: 0,
                    endRadius: 250
                )

                RadialGradient(
                    colors: [
                        palette.glassRefraction.opacity(palette.isDark ? 0.18 : 0.24),
                        .clear
                    ],
                    center: UnitPoint(x: 0.92, y: 0.92),
                    startRadius: 0,
                    endRadius: 250
                )

                LinearGradient(
                    colors: [
                        Color.white.opacity(palette.isDark ? 0.07 : 0.30),
                        .clear,
                        Color.white.opacity(palette.isDark ? 0.02 : 0.12)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
        }
    }
}

private struct DeckPalette {
    let isDark: Bool
    let panelTone: PanelTone

    init(colorScheme: ColorScheme, panelTone: PanelTone) {
        isDark = colorScheme == .dark
        self.panelTone = panelTone
    }

    var panelBase: Color {
        switch panelTone {
        case .glacier:
            return isDark ? Color(hex: 0x171D26) : Color(hex: 0xEEF3F7)
        case .fog:
            return isDark ? Color(hex: 0x1B1D21) : Color(hex: 0xF1F2F4)
        case .celadon:
            return isDark ? Color(hex: 0x17201E) : Color(hex: 0xEDF3F0)
        case .violetSmoke:
            return isDark ? Color(hex: 0x1C1A23) : Color(hex: 0xF1EFF5)
        case .crystalGlass:
            return isDark ? Color(hex: 0x18222B) : Color(hex: 0xEAF2F7)
        case .pearlGlass:
            return isDark ? Color(hex: 0x252422) : Color(hex: 0xF8F7F3)
        case .seaGlass:
            return isDark ? Color(hex: 0x172321) : Color(hex: 0xE8F1EE)
        case .moonGlass:
            return isDark ? Color(hex: 0x1B1E29) : Color(hex: 0xECEFF6)
        }
    }

    var panelTint: Color {
        switch panelTone {
        case .glacier:
            return isDark ? Color(hex: 0x34445A) : Color(hex: 0xD5E2EE)
        case .fog:
            return isDark ? Color(hex: 0x3A3F46) : Color(hex: 0xDDE1E5)
        case .celadon:
            return isDark ? Color(hex: 0x314840) : Color(hex: 0xD1E2DA)
        case .violetSmoke:
            return isDark ? Color(hex: 0x443B52) : Color(hex: 0xDDD7E8)
        case .crystalGlass:
            return isDark ? Color(hex: 0x355166) : Color(hex: 0xC4DAE7)
        case .pearlGlass:
            return isDark ? Color(hex: 0x55514A) : Color(hex: 0xE9E5DD)
        case .seaGlass:
            return isDark ? Color(hex: 0x31534C) : Color(hex: 0xC3DDD6)
        case .moonGlass:
            return isDark ? Color(hex: 0x3F4863) : Color(hex: 0xCBD3E5)
        }
    }

    var isGlass: Bool {
        switch panelTone {
        case .crystalGlass, .pearlGlass, .seaGlass, .moonGlass:
            return true
        case .glacier, .fog, .celadon, .violetSmoke:
            return false
        }
    }

    var glassHighlight: Color {
        switch panelTone {
        case .crystalGlass:
            return Color(hex: 0xF7FCFF)
        case .pearlGlass:
            return Color(hex: 0xFFFDF8)
        case .seaGlass:
            return Color(hex: 0xF4FFFB)
        case .moonGlass:
            return Color(hex: 0xFAF9FF)
        case .glacier, .fog, .celadon, .violetSmoke:
            return .white
        }
    }

    var glassRefraction: Color {
        switch panelTone {
        case .crystalGlass:
            return isDark ? Color(hex: 0x4D7895) : Color(hex: 0xA8CDE0)
        case .pearlGlass:
            return isDark ? Color(hex: 0x81786D) : Color(hex: 0xE3DDD3)
        case .seaGlass:
            return isDark ? Color(hex: 0x47776C) : Color(hex: 0xABD2C8)
        case .moonGlass:
            return isDark ? Color(hex: 0x59678E) : Color(hex: 0xB8C4DF)
        case .glacier, .fog, .celadon, .violetSmoke:
            return panelTint
        }
    }
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
    var listMarkText: Color {
        isDark ? Color(hex: 0xAAB8C5) : Color(hex: 0x71879B)
    }
    var progressTrack: Color { Color.white.opacity(isDark ? 0.10 : 0.30) }

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

func reorderedProviderIDs(
    _ ids: [UUID],
    moving sourceID: UUID,
    to destinationID: UUID
) -> [UUID] {
    guard sourceID != destinationID,
          let sourceIndex = ids.firstIndex(of: sourceID),
          let destinationIndex = ids.firstIndex(of: destinationID) else {
        return ids
    }

    var result = ids
    let movedID = result.remove(at: sourceIndex)
    result.insert(movedID, at: destinationIndex)
    return result
}

func providerListViewportHeight(accountCount: Int) -> CGFloat {
    let visibleCount = max(1, min(accountCount, 3))
    return CGFloat(visibleCount * 34 + max(0, visibleCount - 1) * 3)
}

func relativeProviderID(
    in ids: [UUID],
    from selectedID: UUID?,
    offset: Int
) -> UUID? {
    guard !ids.isEmpty else {
        return nil
    }

    let currentIndex = selectedID.flatMap(ids.firstIndex(of:)) ?? 0
    let normalizedOffset = offset % ids.count
    let nextIndex = (
        currentIndex + normalizedOffset + ids.count
    ) % ids.count
    return ids[nextIndex]
}

func cardNavigationOffset(
    horizontal: CGFloat,
    vertical: CGFloat,
    verticalPositiveMeansPrevious: Bool
) -> Int {
    if abs(horizontal) > abs(vertical) {
        return horizontal < 0 ? 1 : -1
    }
    if verticalPositiveMeansPrevious {
        return vertical > 0 ? -1 : 1
    }
    return vertical > 0 ? 1 : -1
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

func updateTimestamp(
    _ date: Date,
    timeZone: TimeZone = .autoupdatingCurrent
) -> String {
    "\(formattedDate(date, dateFormat: "M月d日 HH:mm", timeZone: timeZone)) 更新"
}

private func shortUpdateTimestamp(
    _ date: Date,
    timeZone: TimeZone = .autoupdatingCurrent
) -> String {
    "\(formattedDate(date, dateFormat: "HH:mm", timeZone: timeZone)) 更新"
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

private func percentageNumber(_ value: Decimal) -> String {
    "\(Int((decimalDouble(value) * 100).rounded()))"
}

private func percentage(_ value: Decimal) -> String {
    "\(percentageNumber(value))%"
}

private func moneyAmount(_ value: Decimal) -> String {
    NSDecimalNumber(decimal: value).stringValue
}

private func durationUntilReset(
    _ date: Date?,
    from referenceDate: Date
) -> String {
    guard let date else {
        return "时间未知"
    }

    let seconds = max(0, Int(date.timeIntervalSince(referenceDate)))
    if seconds >= 86_400 {
        return "\(Int(ceil(Double(seconds) / 86_400))) 天"
    }
    if seconds >= 3_600 {
        let hours = seconds / 3_600
        let minutes = (seconds % 3_600) / 60
        return minutes == 0 ? "\(hours) 小时" : "\(hours)时 \(minutes)分"
    }
    if seconds >= 60 {
        return "\(max(1, seconds / 60)) 分钟"
    }
    return "< 1 分钟"
}

private func compactTokenCount(_ summary: UsageSummary) -> String {
    let total = (summary.inputTokens ?? 0) + (summary.outputTokens ?? 0)
    return total == 0 ? "—" : compactCount(total)
}

private func compactCount(_ value: Int64) -> String {
    let magnitude = Double(value)
    if magnitude >= 1_000_000 {
        return formattedCompactNumber(magnitude / 1_000_000, suffix: "M")
    }
    if magnitude >= 1_000 {
        return formattedCompactNumber(magnitude / 1_000, suffix: "K")
    }
    return "\(value)"
}

private func formattedCompactNumber(
    _ value: Double,
    suffix: String
) -> String {
    let precision = value >= 100 ? 0 : (value >= 10 ? 1 : 2)
    return "\(String(format: "%.\(precision)f", value))\(suffix)"
}

private func averageRequestCost(_ summary: UsageSummary) -> String {
    guard let spend = summary.spend,
          let requestCount = summary.requestCount,
          requestCount > 0 else {
        return "—"
    }

    let average =
        NSDecimalNumber(decimal: spend.amount).doubleValue
        / Double(requestCount)
    return "\(String(format: "%.2f", average)) \(spend.currencyCode)"
}

private func providerLogoAssetName(
    providerID: ProviderID,
    displayName: String
) -> String? {
    let identity = "\(providerID.rawValue) \(displayName)".lowercased()

    if identity.contains("codex") || identity.contains("openai") {
        return "codex"
    }
    if identity.contains("deepseek") {
        return "deepseek"
    }
    if identity.contains("new-api") || identity.contains("new api") {
        return "new-api"
    }
    return nil
}
