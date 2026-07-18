import Foundation
import MiracleDeckCore

public enum MockProvider {
    public static func sampleSnapshots(now: Date = Date()) -> [ProviderSnapshot] {
        [
            ProviderSnapshot(
                providerID: ProviderID(rawValue: "mock.deepseek"),
                displayName: "DeepSeek",
                accountName: "Official API",
                category: .api,
                balance: Money(amount: 86.42, currencyCode: "CNY"),
                usage: [
                    UsageSummary(
                        period: DateInterval(
                            start: now.addingTimeInterval(-604_800),
                            end: now
                        ),
                        inputTokens: 1_248_000,
                        outputTokens: 384_000,
                        requestCount: 184,
                        spend: Money(amount: 12.64, currencyCode: "CNY")
                    )
                ],
                fetchedAt: now,
                source: .init(
                    kind: .officialAPI,
                    stability: .local,
                    label: "Mock official API"
                ),
                status: .healthy
            ),
            ProviderSnapshot(
                providerID: ProviderID(rawValue: "mock.codex"),
                displayName: "Codex",
                accountName: "Plus",
                category: .subscription,
                quotaWindows: [
                    QuotaWindow(
                        id: "five-hour",
                        title: "5 小时额度",
                        remainingRatio: 0.68,
                        resetsAt: now.addingTimeInterval(2_400)
                    ),
                    QuotaWindow(
                        id: "weekly",
                        title: "每周额度",
                        remainingRatio: 0.31,
                        resetsAt: now.addingTimeInterval(172_800),
                        resetCount: 4
                    )
                ],
                fetchedAt: now,
                source: .init(
                    kind: .localCLI,
                    stability: .local,
                    label: "Mock local provider"
                ),
                status: .warning
            ),
            ProviderSnapshot(
                providerID: ProviderID(rawValue: "mock.new-api"),
                displayName: "New API",
                accountName: "Community relay",
                category: .relay,
                balance: Money(amount: 4.18, currencyCode: "USD"),
                usage: [
                    UsageSummary(
                        period: DateInterval(
                            start: now.addingTimeInterval(-604_800),
                            end: now
                        ),
                        inputTokens: 386_000,
                        outputTokens: 104_000,
                        requestCount: 47,
                        spend: Money(amount: 1.27, currencyCode: "USD"),
                        isEstimated: true
                    )
                ],
                fetchedAt: now,
                source: .init(
                    kind: .compatibleAPI,
                    stability: .local,
                    label: "Mock compatible API"
                ),
                status: .critical
            )
        ]
    }
}
