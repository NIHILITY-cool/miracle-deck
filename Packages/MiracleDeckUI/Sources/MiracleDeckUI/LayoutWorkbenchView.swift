import AppKit
import SwiftUI
import MiracleDeckCore

public struct LayoutWorkbenchView: View {
    private let snapshots: [ProviderSnapshot]
    private let targetStore: DeckLayoutStore

    @StateObject private var editorStore: DeckLayoutStore
    @State private var mode = MonitorDisplayMode.card
    @State private var selectedSnapshotID: UUID?
    @State private var selectedElement = EditableLayoutElement.primary
    @State private var dragOrigin: DeckLayoutPreset?
    @State private var saveMessage = "拖动预览中的元素开始调整"

    public init(
        snapshots: [ProviderSnapshot],
        targetStore: DeckLayoutStore = .shared
    ) {
        self.snapshots = snapshots
        self.targetStore = targetStore
        self._editorStore = StateObject(
            wrappedValue: DeckLayoutStore(
                preset: targetStore.preset,
                persistsChanges: false
            )
        )
        self._selectedSnapshotID = State(
            initialValue: snapshots.first?.id
        )
    }

    public var body: some View {
        HStack(spacing: 0) {
            previewColumn
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            Divider()

            inspector
                .frame(width: 248)
        }
        .frame(minWidth: 690, minHeight: 430)
        .background(Color(nsColor: .windowBackgroundColor))
        .onChange(of: mode) { _, _ in
            ensureValidSelection()
        }
        .onChange(of: selectedSnapshotID) { _, _ in
            ensureValidSelection()
        }
    }

    private var previewColumn: some View {
        VStack(spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text("布局调试台")
                        .font(.system(size: 18, weight: .semibold))

                    Text("实际尺寸预览 · 拖动描边区域调整")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Picker("模式", selection: $mode) {
                    Text("排列").tag(MonitorDisplayMode.arrangement)
                    Text("卡片").tag(MonitorDisplayMode.card)
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .frame(width: 142)
            }

            ZStack {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color(nsColor: .underPageBackgroundColor))

                checkerboard
                    .clipShape(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                    )

                preview
                    .overlay(alignment: .topLeading) {
                        editingOverlay
                    }
                    .shadow(
                        color: Color.black.opacity(0.16),
                        radius: 24,
                        y: 10
                    )
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            HStack {
                Circle()
                    .fill(Color.accentColor)
                    .frame(width: 6, height: 6)
                Text(saveMessage)
                    .font(.system(size: 10.5, weight: .medium))
                    .foregroundStyle(.secondary)
                Spacer()
            }
        }
        .padding(18)
    }

    private var checkerboard: some View {
        Canvas { context, size in
            let tile: CGFloat = 14
            let columns = Int(ceil(size.width / tile))
            let rows = Int(ceil(size.height / tile))

            for row in 0..<rows {
                for column in 0..<columns where (row + column).isMultiple(of: 2) {
                    let rect = CGRect(
                        x: CGFloat(column) * tile,
                        y: CGFloat(row) * tile,
                        width: tile,
                        height: tile
                    )
                    context.fill(
                        Path(rect),
                        with: .color(Color.primary.opacity(0.025))
                    )
                }
            }
        }
        .allowsHitTesting(false)
    }

    private var preview: some View {
        MonitorPanelView(
            snapshots: previewSnapshots,
            initialMode: mode,
            layoutStore: editorStore
        )
        .environment(\.deckAnimationsEnabled, false)
        .id("\(mode.rawValue)-\(selectedSnapshotID?.uuidString ?? "none")")
    }

    private var editingOverlay: some View {
        ZStack(alignment: .topLeading) {
            ForEach(editableElements) { element in
                let rect = elementRect(element)

                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .fill(
                        selectedElement == element
                            ? Color.accentColor.opacity(0.10)
                            : Color.clear
                    )
                    .overlay {
                        RoundedRectangle(cornerRadius: 7, style: .continuous)
                            .stroke(
                                selectedElement == element
                                    ? Color.accentColor
                                    : Color.white.opacity(0.58),
                                style: StrokeStyle(
                                    lineWidth: selectedElement == element ? 1.5 : 1,
                                    dash: selectedElement == element ? [] : [4, 3]
                                )
                            )
                    }
                    .overlay(alignment: .topLeading) {
                        Text(label(for: element))
                            .font(.system(size: 8.5, weight: .semibold))
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(
                                selectedElement == element
                                    ? Color.accentColor
                                    : Color.black.opacity(0.58),
                                in: Capsule()
                            )
                            .foregroundStyle(.white)
                            .offset(y: -11)
                    }
                    .frame(width: rect.width, height: rect.height)
                    .position(x: rect.midX, y: rect.midY)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedElement = element
                    }
                    .gesture(dragGesture(for: element))
            }
        }
        .frame(
            width: editorStore.preset.panelWidth,
            height: editorStore.preset.panelHeight,
            alignment: .topLeading
        )
    }

    private var inspector: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                inspectorSection("预览") {
                    Picker("账户", selection: selectedSnapshotBinding) {
                        ForEach(snapshots) { snapshot in
                            Text(snapshot.displayName)
                                .tag(Optional(snapshot.id))
                        }
                    }
                    .labelsHidden()
                    .frame(maxWidth: .infinity)
                }

                inspectorSection("窗口") {
                    valueRow(
                        label: "宽度",
                        binding: panelWidthBinding,
                        range: 260...420
                    )
                    valueRow(
                        label: "高度",
                        binding: panelHeightBinding,
                        range: 280...480
                    )
                }

                inspectorSection("排列结构") {
                    valueRow(
                        label: "Hero 高度",
                        binding: presetBinding(
                            \.compactHeroHeight,
                            range: 110...200
                        ),
                        range: 110...200
                    )
                    valueRow(
                        label: "外边距",
                        binding: presetBinding(
                            \.arrangementInset,
                            range: 4...18
                        ),
                        range: 4...18
                    )
                    valueRow(
                        label: "整体 Y",
                        binding: presetBinding(
                            \.heroOffsetY,
                            range: 20...72
                        ),
                        range: 20...72
                    )
                }

                inspectorSection("选中元素") {
                    Picker("元素", selection: $selectedElement) {
                        ForEach(editableElements) { element in
                            Text(label(for: element)).tag(element)
                        }
                    }
                    .labelsHidden()
                    .frame(maxWidth: .infinity)

                    valueRow(
                        label: "X",
                        binding: coordinateBinding(\.x),
                        range: 0...360
                    )
                    valueRow(
                        label: "Y",
                        binding: coordinateBinding(\.y),
                        range: 0...420
                    )

                    HStack(spacing: 6) {
                        nudgeButton("←", dx: -1, dy: 0)
                        nudgeButton("↑", dx: 0, dy: -1)
                        nudgeButton("↓", dx: 0, dy: 1)
                        nudgeButton("→", dx: 1, dy: 0)
                    }
                }

                inspectorSection("样式") {
                    if mode == .arrangement {
                        valueRow(
                            label: "列表数字",
                            binding: presetBinding(
                                \.listMetricFontSize,
                                range: 10...15
                            ),
                            range: 10...15
                        )
                        valueRow(
                            label: "状态点",
                            binding: presetBinding(
                                \.compactStatusSize,
                                range: 5...14
                            ),
                            range: 5...14
                        )

                        if selectedSnapshot?.balance != nil {
                            valueRow(
                                label: "Hero Logo",
                                binding: presetBinding(
                                    \.compactLogoSize,
                                    range: 18...42
                                ),
                                range: 18...42
                            )
                        }
                    } else {
                        valueRow(
                            label: "卡片 Logo",
                            binding: presetBinding(
                                \.expandedLogoSize,
                                range: 28...64
                            ),
                            range: 28...64
                        )
                    }
                }

                Divider()

                Button("保存并应用") {
                    targetStore.apply(editorStore.preset)
                    saveMessage = "已保存，重新打开状态栏卡片即可查看"
                }
                .buttonStyle(.borderedProminent)
                .frame(maxWidth: .infinity)

                HStack {
                    Button("恢复默认") {
                        editorStore.reset(persist: false)
                        saveMessage = "预览已恢复默认，点击保存后应用"
                    }

                    Button("复制 JSON") {
                        copyPresetJSON()
                    }
                }
            }
            .padding(16)
        }
    }

    private func inspectorSection<Content: View>(
        _ title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 9) {
            Text(title.uppercased())
                .font(.system(size: 9.5, weight: .semibold))
                .tracking(1.1)
                .foregroundStyle(.secondary)

            content()
        }
    }

    private func valueRow(
        label: String,
        binding: Binding<CGFloat>,
        range: ClosedRange<CGFloat>
    ) -> some View {
        let doubleBinding = Binding<Double>(
            get: { Double(binding.wrappedValue) },
            set: { binding.wrappedValue = CGFloat($0) }
        )

        return HStack {
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.secondary)
            Spacer()
            TextField(
                label,
                value: doubleBinding,
                format: .number.precision(.fractionLength(0))
            )
            .textFieldStyle(.roundedBorder)
            .multilineTextAlignment(.trailing)
            .frame(width: 58)

            Stepper(
                "",
                value: doubleBinding,
                in: Double(range.lowerBound)...Double(range.upperBound),
                step: 1
            )
                .labelsHidden()
        }
    }

    private func nudgeButton(
        _ title: String,
        dx: CGFloat,
        dy: CGFloat
    ) -> some View {
        Button(title) {
            moveSelectedElement(dx: dx, dy: dy)
        }
        .buttonStyle(.bordered)
        .frame(maxWidth: .infinity)
    }

    private var previewSnapshots: [ProviderSnapshot] {
        guard let selectedSnapshotID,
              let selected = snapshots.first(
                where: { $0.id == selectedSnapshotID }
              ) else {
            return snapshots
        }
        return [selected] + snapshots.filter { $0.id != selectedSnapshotID }
    }

    private var selectedSnapshot: ProviderSnapshot? {
        previewSnapshots.first
    }

    private func label(for element: EditableLayoutElement) -> String {
        guard element == .primary else {
            return element.label
        }
        return selectedSnapshot?.balance == nil
            ? "额度主数字"
            : "余额主数字"
    }

    private var editableElements: [EditableLayoutElement] {
        if mode == .arrangement {
            var elements: [EditableLayoutElement] = [
                .identity,
                .primary,
                .status
            ]
            if selectedSnapshot?.quotaWindows.first != nil {
                elements.append(.progress)
            } else {
                elements.append(contentsOf: [.updateTime, .compactLogo])
            }
            return elements
        }

        var elements: [EditableLayoutElement] = [.identity, .primary]
        if selectedSnapshot?.quotaWindows.first != nil {
            elements.append(.progress)
        } else {
            elements.append(.insights)
        }
        elements.append(contentsOf: [.secondary, .expandedLogo])
        return elements
    }

    private func elementRect(_ element: EditableLayoutElement) -> CGRect {
        let preset = editorStore.preset
        let heroOrigin = mode == .arrangement
            ? CGPoint(x: preset.arrangementInset, y: preset.heroOffsetY)
            : .zero
        let point = point(for: element, in: preset)
        let size = element.overlaySize(panelWidth: preset.panelWidth)

        return CGRect(
            x: heroOrigin.x + point.x,
            y: heroOrigin.y + point.y,
            width: max(
                16,
                min(size.width, preset.panelWidth - point.x)
            ),
            height: size.height
        )
    }

    private func dragGesture(
        for element: EditableLayoutElement
    ) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                selectedElement = element
                let origin = dragOrigin ?? editorStore.preset
                if dragOrigin == nil {
                    dragOrigin = origin
                }

                var updated = origin
                let start = point(for: element, in: origin)
                setPoint(
                    DeckLayoutPoint(
                        x: max(0, start.x + value.translation.width),
                        y: max(0, start.y + value.translation.height)
                    ),
                    for: element,
                    in: &updated
                )
                editorStore.preset = updated
            }
            .onEnded { _ in
                dragOrigin = nil
                saveMessage = "位置已修改，点击“保存并应用”写入卡片"
            }
    }

    private func point(
        for element: EditableLayoutElement,
        in preset: DeckLayoutPreset
    ) -> DeckLayoutPoint {
        switch (mode, element) {
        case (.arrangement, .identity):
            preset.compactIdentity
        case (.arrangement, .primary):
            selectedSnapshot?.balance == nil
                ? preset.compactQuotaPrimary
                : preset.compactBalancePrimary
        case (.arrangement, .progress):
            preset.compactProgress
        case (.arrangement, .status):
            preset.compactStatus
        case (.arrangement, .updateTime):
            preset.compactFooter
        case (.arrangement, .compactLogo):
            preset.compactLogo
        case (.card, .identity):
            preset.expandedIdentity
        case (.card, .primary):
            selectedSnapshot?.balance == nil
                ? preset.expandedQuotaPrimary
                : preset.expandedBalancePrimary
        case (.card, .progress):
            preset.expandedProgress
        case (.card, .insights):
            selectedSnapshot?.balance == nil
                ? preset.expandedInsights
                : preset.expandedBalanceInsights
        case (.card, .secondary):
            preset.expandedSecondary
        case (.card, .expandedLogo):
            preset.expandedLogo
        default:
            DeckLayoutPoint(x: 0, y: 0)
        }
    }

    private func setPoint(
        _ point: DeckLayoutPoint,
        for element: EditableLayoutElement,
        in preset: inout DeckLayoutPreset
    ) {
        let point = constrainedPoint(
            point,
            for: element,
            in: preset
        )

        switch (mode, element) {
        case (.arrangement, .identity):
            preset.compactIdentity = point
        case (.arrangement, .primary):
            if selectedSnapshot?.balance == nil {
                preset.compactQuotaPrimary = point
            } else {
                preset.compactBalancePrimary = point
            }
        case (.arrangement, .progress):
            preset.compactProgress = point
        case (.arrangement, .status):
            preset.compactStatus = point
        case (.arrangement, .updateTime):
            preset.compactFooter = point
        case (.arrangement, .compactLogo):
            preset.compactLogo = point
        case (.card, .identity):
            preset.expandedIdentity = point
        case (.card, .primary):
            if selectedSnapshot?.balance == nil {
                preset.expandedQuotaPrimary = point
            } else {
                preset.expandedBalancePrimary = point
            }
        case (.card, .progress):
            preset.expandedProgress = point
        case (.card, .insights):
            if selectedSnapshot?.balance == nil {
                preset.expandedInsights = point
            } else {
                preset.expandedBalanceInsights = point
            }
        case (.card, .secondary):
            preset.expandedSecondary = point
        case (.card, .expandedLogo):
            preset.expandedLogo = point
        default:
            break
        }
    }

    private func constrainedPoint(
        _ point: DeckLayoutPoint,
        for element: EditableLayoutElement,
        in preset: DeckLayoutPreset
    ) -> DeckLayoutPoint {
        let size = element.overlaySize(panelWidth: preset.panelWidth)
        let contentWidth = mode == .arrangement
            ? preset.panelWidth - preset.arrangementInset * 2
            : preset.panelWidth
        let contentHeight = mode == .arrangement
            ? preset.compactHeroHeight
            : preset.panelHeight

        return DeckLayoutPoint(
            x: min(max(0, point.x), max(0, contentWidth - size.width)),
            y: min(max(0, point.y), max(0, contentHeight - size.height))
        )
    }

    private func ensureValidSelection() {
        if !editableElements.contains(selectedElement) {
            selectedElement = editableElements.first ?? .primary
        }
    }

    private func moveSelectedElement(dx: CGFloat, dy: CGFloat) {
        var preset = editorStore.preset
        let current = point(for: selectedElement, in: preset)
        setPoint(
            DeckLayoutPoint(
                x: max(0, current.x + dx),
                y: max(0, current.y + dy)
            ),
            for: selectedElement,
            in: &preset
        )
        editorStore.preset = preset
        saveMessage = "位置已微调，点击“保存并应用”写入卡片"
    }

    private var selectedSnapshotBinding: Binding<UUID?> {
        Binding(
            get: { selectedSnapshotID },
            set: { selectedSnapshotID = $0 }
        )
    }

    private var panelWidthBinding: Binding<CGFloat> {
        Binding(
            get: { editorStore.preset.panelWidth },
            set: { newValue in
                var preset = editorStore.preset
                preset.panelWidth = min(max(newValue, 260), 420)
                editorStore.preset = preset
            }
        )
    }

    private var panelHeightBinding: Binding<CGFloat> {
        Binding(
            get: { editorStore.preset.panelHeight },
            set: { newValue in
                var preset = editorStore.preset
                preset.panelHeight = min(max(newValue, 280), 480)
                editorStore.preset = preset
            }
        )
    }

    private func presetBinding(
        _ keyPath: WritableKeyPath<DeckLayoutPreset, CGFloat>,
        range: ClosedRange<CGFloat>
    ) -> Binding<CGFloat> {
        Binding(
            get: { editorStore.preset[keyPath: keyPath] },
            set: { newValue in
                var preset = editorStore.preset
                preset[keyPath: keyPath] = min(
                    max(newValue, range.lowerBound),
                    range.upperBound
                )
                editorStore.preset = preset
            }
        )
    }

    private func coordinateBinding(
        _ keyPath: WritableKeyPath<DeckLayoutPoint, CGFloat>
    ) -> Binding<CGFloat> {
        Binding(
            get: {
                point(
                    for: selectedElement,
                    in: editorStore.preset
                )[keyPath: keyPath]
            },
            set: { newValue in
                var preset = editorStore.preset
                var point = point(for: selectedElement, in: preset)
                point[keyPath: keyPath] = max(0, newValue)
                setPoint(
                    point,
                    for: selectedElement,
                    in: &preset
                )
                editorStore.preset = preset
            }
        )
    }

    private func copyPresetJSON() {
        guard let json = editorStore.encodedPreset() else {
            saveMessage = "无法生成 JSON"
            return
        }

        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(json, forType: .string)
        saveMessage = "布局 JSON 已复制"
    }
}

private enum EditableLayoutElement: String, CaseIterable, Identifiable {
    case identity
    case primary
    case progress
    case status
    case updateTime
    case compactLogo
    case insights
    case secondary
    case expandedLogo

    var id: String { rawValue }

    var label: String {
        switch self {
        case .identity:
            "账户标题"
        case .primary:
            "主数字"
        case .progress:
            "额度进度"
        case .status:
            "状态点"
        case .updateTime:
            "更新时间"
        case .compactLogo:
            "Hero Logo"
        case .insights:
            "数据行"
        case .secondary:
            "次要指标"
        case .expandedLogo:
            "卡片 Logo"
        }
    }

    func overlaySize(panelWidth: CGFloat) -> CGSize {
        switch self {
        case .identity:
            CGSize(width: min(180, panelWidth - 40), height: 38)
        case .primary:
            CGSize(width: min(220, panelWidth - 40), height: 76)
        case .progress:
            CGSize(width: max(120, panelWidth - 40), height: 34)
        case .status:
            CGSize(width: 18, height: 18)
        case .updateTime:
            CGSize(width: 110, height: 18)
        case .compactLogo:
            CGSize(width: 40, height: 40)
        case .insights:
            CGSize(width: max(120, panelWidth - 40), height: 42)
        case .secondary:
            CGSize(width: 194, height: 90)
        case .expandedLogo:
            CGSize(width: 56, height: 56)
        }
    }
}
