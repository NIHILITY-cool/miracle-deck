import Foundation

public struct ProviderID: RawRepresentable, Hashable, Codable, Sendable {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }
}

public struct AccountID: RawRepresentable, Hashable, Codable, Sendable {
    public let rawValue: UUID

    public init(rawValue: UUID = UUID()) {
        self.rawValue = rawValue
    }
}

public struct Money: Hashable, Codable, Sendable {
    public let amount: Decimal
    public let currencyCode: String

    public init(amount: Decimal, currencyCode: String) {
        self.amount = amount
        self.currencyCode = currencyCode
    }
}

public enum ProviderCategory: String, Codable, Sendable {
    case api
    case subscription
    case relay
    case local
}

public enum ProviderStatus: String, Codable, Sendable {
    case healthy
    case warning
    case critical
    case unavailable
}

public enum DataSourceKind: String, Codable, Sendable {
    case officialAPI
    case compatibleAPI
    case oauth
    case localCLI
    case localLog
    case webSession
}

public enum StabilityLevel: String, Codable, Sendable {
    case stable
    case compatible
    case local
    case experimental
}

public struct DataSourceDescriptor: Hashable, Codable, Sendable {
    public let kind: DataSourceKind
    public let stability: StabilityLevel
    public let label: String

    public init(
        kind: DataSourceKind,
        stability: StabilityLevel,
        label: String
    ) {
        self.kind = kind
        self.stability = stability
        self.label = label
    }
}

public struct QuotaWindow: Identifiable, Hashable, Codable, Sendable {
    public let id: String
    public let title: String
    public let remainingRatio: Decimal?
    public let resetsAt: Date?

    public init(
        id: String,
        title: String,
        remainingRatio: Decimal?,
        resetsAt: Date?
    ) {
        self.id = id
        self.title = title
        self.remainingRatio = remainingRatio
        self.resetsAt = resetsAt
    }
}

public struct UsageSummary: Hashable, Codable, Sendable {
    public let period: DateInterval
    public let inputTokens: Int64?
    public let outputTokens: Int64?
    public let requestCount: Int64?
    public let spend: Money?
    public let isEstimated: Bool

    public init(
        period: DateInterval,
        inputTokens: Int64? = nil,
        outputTokens: Int64? = nil,
        requestCount: Int64? = nil,
        spend: Money? = nil,
        isEstimated: Bool = false
    ) {
        self.period = period
        self.inputTokens = inputTokens
        self.outputTokens = outputTokens
        self.requestCount = requestCount
        self.spend = spend
        self.isEstimated = isEstimated
    }
}

public struct ProviderSnapshot: Identifiable, Hashable, Codable, Sendable {
    public let id: UUID
    public let accountID: AccountID
    public let providerID: ProviderID
    public let displayName: String
    public let accountName: String
    public let category: ProviderCategory
    public let balance: Money?
    public let quotaWindows: [QuotaWindow]
    public let usage: [UsageSummary]
    public let fetchedAt: Date
    public let source: DataSourceDescriptor
    public let status: ProviderStatus

    public init(
        id: UUID = UUID(),
        accountID: AccountID = AccountID(),
        providerID: ProviderID,
        displayName: String,
        accountName: String,
        category: ProviderCategory,
        balance: Money? = nil,
        quotaWindows: [QuotaWindow] = [],
        usage: [UsageSummary] = [],
        fetchedAt: Date = Date(),
        source: DataSourceDescriptor,
        status: ProviderStatus
    ) {
        self.id = id
        self.accountID = accountID
        self.providerID = providerID
        self.displayName = displayName
        self.accountName = accountName
        self.category = category
        self.balance = balance
        self.quotaWindows = quotaWindows
        self.usage = usage
        self.fetchedAt = fetchedAt
        self.source = source
        self.status = status
    }
}
