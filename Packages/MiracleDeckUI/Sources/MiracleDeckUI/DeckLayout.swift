import Combine
import CoreGraphics
import Foundation

public struct DeckLayoutPoint: Codable, Equatable, Sendable {
    public var x: CGFloat
    public var y: CGFloat

    public init(x: CGFloat, y: CGFloat) {
        self.x = x
        self.y = y
    }
}

public struct DeckLayoutPreset: Codable, Equatable, Sendable {
    public var panelWidth: CGFloat
    public var panelHeight: CGFloat
    public var compactHeroHeight: CGFloat
    public var arrangementInset: CGFloat
    public var arrangementSpacing: CGFloat
    public var heroOffsetY: CGFloat

    public var compactIdentity: DeckLayoutPoint
    public var compactQuotaPrimary: DeckLayoutPoint
    public var compactBalancePrimary: DeckLayoutPoint
    public var compactProgress: DeckLayoutPoint
    public var compactStatus: DeckLayoutPoint
    public var compactFooter: DeckLayoutPoint
    public var compactLogo: DeckLayoutPoint

    public var expandedIdentity: DeckLayoutPoint
    public var expandedQuotaPrimary: DeckLayoutPoint
    public var expandedBalancePrimary: DeckLayoutPoint
    public var expandedProgress: DeckLayoutPoint
    public var expandedInsights: DeckLayoutPoint
    public var expandedBalanceInsights: DeckLayoutPoint
    public var expandedSecondary: DeckLayoutPoint
    public var expandedLogo: DeckLayoutPoint

    public var compactStatusSize: CGFloat
    public var compactLogoSize: CGFloat
    public var expandedLogoSize: CGFloat
    public var listMetricFontSize: CGFloat

    public init(
        panelWidth: CGFloat,
        panelHeight: CGFloat,
        compactHeroHeight: CGFloat,
        arrangementInset: CGFloat,
        arrangementSpacing: CGFloat,
        heroOffsetY: CGFloat,
        compactIdentity: DeckLayoutPoint,
        compactQuotaPrimary: DeckLayoutPoint,
        compactBalancePrimary: DeckLayoutPoint,
        compactProgress: DeckLayoutPoint,
        compactStatus: DeckLayoutPoint,
        compactFooter: DeckLayoutPoint,
        compactLogo: DeckLayoutPoint,
        expandedIdentity: DeckLayoutPoint,
        expandedQuotaPrimary: DeckLayoutPoint,
        expandedBalancePrimary: DeckLayoutPoint,
        expandedProgress: DeckLayoutPoint,
        expandedInsights: DeckLayoutPoint,
        expandedBalanceInsights: DeckLayoutPoint,
        expandedSecondary: DeckLayoutPoint,
        expandedLogo: DeckLayoutPoint,
        compactStatusSize: CGFloat,
        compactLogoSize: CGFloat,
        expandedLogoSize: CGFloat,
        listMetricFontSize: CGFloat
    ) {
        self.panelWidth = panelWidth
        self.panelHeight = panelHeight
        self.compactHeroHeight = compactHeroHeight
        self.arrangementInset = arrangementInset
        self.arrangementSpacing = arrangementSpacing
        self.heroOffsetY = heroOffsetY
        self.compactIdentity = compactIdentity
        self.compactQuotaPrimary = compactQuotaPrimary
        self.compactBalancePrimary = compactBalancePrimary
        self.compactProgress = compactProgress
        self.compactStatus = compactStatus
        self.compactFooter = compactFooter
        self.compactLogo = compactLogo
        self.expandedIdentity = expandedIdentity
        self.expandedQuotaPrimary = expandedQuotaPrimary
        self.expandedBalancePrimary = expandedBalancePrimary
        self.expandedProgress = expandedProgress
        self.expandedInsights = expandedInsights
        self.expandedBalanceInsights = expandedBalanceInsights
        self.expandedSecondary = expandedSecondary
        self.expandedLogo = expandedLogo
        self.compactStatusSize = compactStatusSize
        self.compactLogoSize = compactLogoSize
        self.expandedLogoSize = expandedLogoSize
        self.listMetricFontSize = listMetricFontSize
    }

    public static let `default` = DeckLayoutPreset(
        panelWidth: 294,
        panelHeight: 320,
        compactHeroHeight: 138,
        arrangementInset: 8,
        arrangementSpacing: 6,
        heroOffsetY: 40,
        compactIdentity: DeckLayoutPoint(x: 15, y: 12),
        compactQuotaPrimary: DeckLayoutPoint(x: 15, y: 43),
        compactBalancePrimary: DeckLayoutPoint(x: 15, y: 51),
        compactProgress: DeckLayoutPoint(x: 15, y: 104),
        compactStatus: DeckLayoutPoint(x: 252, y: 15),
        compactFooter: DeckLayoutPoint(x: 15, y: 116),
        compactLogo: DeckLayoutPoint(x: 235, y: 98),
        expandedIdentity: DeckLayoutPoint(x: 20, y: 18),
        expandedQuotaPrimary: DeckLayoutPoint(x: 20, y: 76),
        expandedBalancePrimary: DeckLayoutPoint(x: 20, y: 90),
        expandedProgress: DeckLayoutPoint(x: 20, y: 164),
        expandedInsights: DeckLayoutPoint(x: 20, y: 192),
        expandedBalanceInsights: DeckLayoutPoint(x: 20, y: 158),
        expandedSecondary: DeckLayoutPoint(x: 20, y: 212),
        expandedLogo: DeckLayoutPoint(x: 230, y: 258),
        compactStatusSize: 8,
        compactLogoSize: 28,
        expandedLogoSize: 44,
        listMetricFontSize: 12
    )

    public var panelSize: CGSize {
        CGSize(width: panelWidth, height: panelHeight)
    }

    public func normalized() -> DeckLayoutPreset {
        var result = self
        result.panelWidth = min(max(panelWidth, 260), 420)
        result.panelHeight = min(max(panelHeight, 280), 480)
        result.compactHeroHeight = min(max(compactHeroHeight, 110), 200)
        result.arrangementInset = min(max(arrangementInset, 4), 18)
        result.arrangementSpacing = min(max(arrangementSpacing, 2), 14)
        result.heroOffsetY = min(max(heroOffsetY, 20), 72)
        result.compactStatusSize = min(max(compactStatusSize, 5), 14)
        result.compactLogoSize = min(max(compactLogoSize, 18), 42)
        result.expandedLogoSize = min(max(expandedLogoSize, 28), 64)
        result.listMetricFontSize = min(max(listMetricFontSize, 10), 15)
        return result
    }
}

@MainActor
public final class DeckLayoutStore: ObservableObject {
    public static let shared = DeckLayoutStore()

    @Published public var preset: DeckLayoutPreset

    private let defaults: UserDefaults?
    private let defaultsKey = "miracledeck.debug-layout.v5"

    public init(
        preset: DeckLayoutPreset? = nil,
        persistsChanges: Bool = true
    ) {
        self.defaults = persistsChanges ? .standard : nil

        if let preset {
            self.preset = preset.normalized()
        } else if persistsChanges,
                  let data = UserDefaults.standard.data(forKey: defaultsKey),
                  let decoded = try? JSONDecoder().decode(
                    DeckLayoutPreset.self,
                    from: data
                  ) {
            self.preset = decoded.normalized()
        } else {
            self.preset = .default
        }
    }

    public func apply(
        _ preset: DeckLayoutPreset,
        persist: Bool = true
    ) {
        self.preset = preset.normalized()
        if persist {
            save()
        }
    }

    public func save() {
        guard let defaults,
              let data = try? JSONEncoder().encode(preset) else {
            return
        }
        defaults.set(data, forKey: defaultsKey)
    }

    public func reset(persist: Bool = true) {
        preset = .default
        if persist {
            save()
        }
    }

    public func encodedPreset() -> String? {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        guard let data = try? encoder.encode(preset) else {
            return nil
        }
        return String(data: data, encoding: .utf8)
    }
}
