import Foundation
import TokenMonitorCore

public enum MockProvider {
    public static func sampleSnapshots(now: Date = Date()) -> [ProviderSnapshot] {
        [
            ProviderSnapshot(
                providerID: ProviderID(rawValue: "mock.deepseek"),
                displayName: "DeepSeek",
                accountName: "Official API",
                category: .api,
                balance: Money(amount: 86.42, currencyCode: "CNY"),
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
                        resetsAt: now.addingTimeInterval(172_800)
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
