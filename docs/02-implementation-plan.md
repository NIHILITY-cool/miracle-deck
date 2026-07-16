# MiracleDeck 项目实施计划与注意事项

> 版本：Draft 1
> 编写日期：2026-07-16
> 目标：把产品调研和视觉方案转化为可执行、可验收、可持续维护的开源项目计划。
> 相关文档：[技术与竞品调研](01-landscape-and-implementation-research.md)、[Quota Float 设计拆解](../design.md)

## 1. 项目目标

MiracleDeck 是一个隐私优先、占用低、原生 macOS 的菜单栏工具，用于集中查看：

- OpenAI、DeepSeek、Anthropic、OpenRouter 等官方 API 的余额、用量和费用；
- New API、One API、LiteLLM 等第三方中转服务的余额与消耗；
- Codex、Claude 等官方订阅套餐的使用窗口和刷新时间；
- Claude Code、Codex 等本地工具日志中的 Token 与估算成本；
- 多个平台、多账户的整体健康状态和异常提醒。

项目的核心价值不是支持最多的平台，而是：

1. 把 API 账户、订阅套餐和第三方中转放到同一入口；
2. 明确区分官方数据、本地数据和估算数据；
3. 对国内常用中转服务提供一等支持；
4. 保持菜单栏应用应有的轻量、快速和低干扰；
5. 建立可测试、可扩展、适合社区贡献的 Provider 架构。

## 2. 非目标

首个稳定版本不负责：

- 代理、转发或修改用户的 LLM 请求；
- 提供完整的团队级 LLM Observability；
- 管理服务商 API Key 的创建、删除或权限；
- 自动充值、购买 credits 或兑换套餐额度；
- 自动切换账号以绕过服务商限制；
- 把 ChatGPT/Claude 套餐额度转换成虚构的 Token 上限；
- 云端同步用户密钥和账户信息；
- 在未经用户明确授权时读取浏览器 Cookie；
- 首发支持 Windows、Linux、iOS 或 Android；
- 承诺非公开接口永久可用。

任何会改变用户账户、消费资金或对外发送数据的功能都不属于监控应用的默认权限。

## 3. 已确定的产品决策

| 决策 | 结论 |
| --- | --- |
| 首发平台 | macOS |
| 最低系统 | macOS 14 Sonoma |
| 技术栈 | Swift 6、SwiftUI、AppKit |
| 菜单栏实现 | `NSStatusItem + NSPanel`，SwiftUI 承载内容 |
| 默认入口 | 菜单栏 Popover |
| 可选入口 | Floating Widget，后续版本提供 |
| 数据架构 | Provider 插件式架构 |
| 凭据存储 | macOS Keychain |
| 普通设置 | Application Support 中的版本化 JSON |
| 快照缓存 | Caches 中的非敏感版本化 JSON |
| 历史数据 | v0.2 引入 SQLite |
| 网络策略 | 直连服务商，默认 HTTPS，支持系统代理 |
| 更新方式 | GitHub Releases + Sparkle |
| 分发方式 | Developer ID 签名、notarization、Homebrew Cask |
| 许可证建议 | MIT |
| 默认语言 | 简体中文，首版同时提供英文 |
| 默认主题 | 跟随系统浅色/深色 |
| App Store | v1 前不作为主要分发渠道 |

## 4. 当前仓库与环境状态

截至 2026-07-17：

- 已安装 Xcode 26.6 和 Swift 6.3.3；
- Xcode 许可、首次启动组件和 macOS SDK 已可用；
- Git 仓库已初始化；
- 已通过 XcodeGen 创建原生 macOS App 工程；
- 已创建 `MiracleDeckCore`、`MiracleDeckProviders` 和
  `MiracleDeckUI` 三个本地 Swift Package；
- 已加入菜单栏、NSPanel、Mock Provider、基础测试和 GitHub Actions；
- 本地 `make verify` 构建和测试通过；
- 系统全局 active developer directory 已切换到完整 Xcode；
- 当前 Debug App 构建成功，4 个基础测试通过。

继续开发前需要完成：

1. 配置 GitHub 分支保护并验证首次 CI；
2. 确定最终项目图标；
3. 创建 Apple Developer 证书与 notarization 配置。

已确定：

```text
Product Name: MiracleDeck
Bundle ID: cool.nihility.miracledeck
Executable: MiracleDeck
```

项目仓库为
[`NIHILITY-cool/miracle-deck`](https://github.com/NIHILITY-cool/miracle-deck)。
公开稳定版本发布前仍需完成正式商标核查。

## 5. 总体交付路线

以下周期以一名主要开发者为估算基础，不是发布日期承诺。

| 阶段 | 目标 | 建议周期 |
| --- | --- | --- |
| Phase 0 | 仓库、Xcode 工程、规范和 CI | 3-5 天 |
| Phase 1 | 菜单栏外壳和视觉原型 | 1-2 周 |
| Phase 2 | Domain、ProviderKit、凭据、缓存和刷新框架 | 1-2 周 |
| Phase 3 | DeepSeek、New API、Codex 三个纵向切片 | 2-3 周 |
| Phase 4 | OpenAI、OpenRouter、Claude、Anthropic | 2-4 周 |
| Phase 5 | 多平台交互、设置、通知和诊断 | 1-2 周 |
| Phase 6 | 性能、安全、可访问性、发布准备 | 1-2 周 |
| Public Beta v0.2 | 收集真实账户兼容性反馈 | 2-4 周 |
| Phase 7 | v0.3 本地历史与 v0.4 扩展能力 | 4-8 周 |
| v1.0 | 修复 Beta 问题并冻结首版能力 | 1-2 周 |

现实情况下，公开 Beta 约需 10-16 周，完整 v1.0 约需 18-28 周。套餐接口变化、签名发布、历史数据库和真实账户兼容性可能显著增加时间。若希望更早发布 v1.0，可以把 v0.3、v0.4 的本地历史和开放扩展调整为 v1.1。

## 6. 版本范围

### 6.1 v0.0.x：工程验证

目标是证明原生菜单栏外壳、Provider 架构和设计语言可行。

包含：

- 菜单栏图标；
- NSPanel 弹窗；
- Mock Provider；
- Provider 摘要卡；
- Provider 紧凑列表；
- 浅色和深色模式；
- 基础设置；
- Swift Testing 或 XCTest；
- GitHub Actions 编译和单元测试。

不连接真实账户。

### 6.2 v0.1 Alpha：核心纵向切片

包含三种最重要的数据形态：

- DeepSeek：官方余额；
- New API/One API：第三方中转余额和期间消耗；
- Codex：订阅额度窗口和刷新时间。

同时完成：

- Keychain；
- 多账户；
- 缓存；
- 手动与定时刷新；
- Stale 状态；
- 统一错误；
- Provider 排序与切换；
- 脱敏诊断；
- 基础通知。

### 6.3 v0.2 Beta：主要平台覆盖

增加：

- OpenAI Organization Usage/Costs；
- OpenRouter Credits；
- Claude 套餐 Usage；
- Anthropic Organization Usage/Cost；
- 余额与消费的基础历史；
- Floating Widget；
- 菜单栏固定指标；
- 登录时启动；
- Sparkle Beta 更新。

### 6.4 v0.3：本地 Token 与历史

增加：

- Claude Code JSONL 增量扫描；
- Codex JSONL 增量扫描；
- Today、Yesterday、7d、30d 聚合；
- 模型价格表；
- 本地估算成本；
- 余额变化历史；
- 消费趋势和预算提醒。

### 6.5 v0.4：开放扩展

增加：

- LiteLLM Proxy；
- Custom HTTP Provider；
- Provider manifest；
- Provider fixture 验证工具；
- 配置导入导出；
- localhost 只读 API；
- CLI JSON 输出；
- 社区 Provider 模板。

### 6.6 v1.0：稳定承诺

v1.0 只在以下条件满足后发布：

- 核心 Provider 已通过至少一个月 Beta 验证；
- 无已知密钥泄露路径；
- 无高优先级崩溃；
- 升级不会丢失账户配置；
- 数据迁移有回滚策略；
- 签名与自动更新稳定；
- 中英文界面完成；
- 可访问性和性能预算达标；
- 文档、隐私政策和安全策略完整。

## 7. 系统架构

### 7.1 推荐工程结构

建议使用一个 Xcode App 工程，加若干本地 Swift Package。不要在首版引入复杂的多仓库结构。

```text
miracle-deck/
  MiracleDeck.xcodeproj
  App/
    MiracleDeckApp.swift
    AppDelegate.swift
    StatusItemController.swift
    PanelController.swift
    SettingsWindowController.swift
  Packages/
    MiracleDeckCore/
      Sources/
        Domain/
        ProviderKit/
        Persistence/
        Networking/
        Diagnostics/
      Tests/
    MiracleDeckProviders/
      Sources/
        DeepSeekProvider/
        NewAPIProvider/
        CodexProvider/
        OpenAIProvider/
        OpenRouterProvider/
        ClaudeProvider/
        AnthropicProvider/
      Tests/
    MiracleDeckUI/
      Sources/
        DesignSystem/
        Components/
        Features/
      Tests/
  Resources/
    Assets.xcassets
    Localizable.xcstrings
    ProviderMetadata.json
    BuiltInPricing.json
  Tests/
    AppTests/
    UITests/
    Fixtures/
  docs/
```

这样可以：

- 让 Domain 和 Provider 逻辑不依赖 AppKit；
- 单独测试 Provider；
- 避免所有代码堆在 App Target；
- 为未来 CLI、Widget 和其他平台复用核心层。

### 7.2 模块职责

#### App

负责：

- 应用生命周期；
- 菜单栏图标；
- Panel 显示、定位和关闭；
- 设置窗口；
- 登录时启动；
- 通知权限；
- Sparkle 更新；
- 全局快捷键；
- Floating Widget 生命周期。

App 不负责解析 Provider 响应。

#### Domain

负责：

- 统一数据模型；
- 金额、Token、额度窗口和刷新时间；
- 数据来源和稳定等级；
- Freshness；
- 错误分类；
- UI 展示需要的语义，而不是具体样式。

Domain 不依赖 SwiftUI、AppKit、Keychain 或 URLSession。

#### ProviderKit

负责：

- Provider 协议；
- Provider 注册表；
- Provider 能力声明；
- Account 配置；
- Fetch Context；
- 刷新调度；
- 并发控制；
- Provider 健康状态；
- Fixture contract。

#### Networking

负责：

- 统一 `URLSession`；
- 请求超时；
- User-Agent；
- 重试与退避；
- 429 处理；
- HTTP 状态映射；
- 响应大小限制；
- 日志脱敏；
- 系统代理；
- TLS 安全策略。

#### Persistence

负责：

- Keychain 凭据；
- 账户配置；
- Provider 顺序与收藏；
- 快照缓存；
- 历史数据库；
- Schema 版本和迁移；
- 配置导入导出。

#### Diagnostics

负责：

- `OSLog`；
- 统一错误信息；
- 脱敏；
- Provider 诊断报告；
- 用户可复制的安全诊断；
- Live contract test 的结果。

#### MiracleDeckUI

负责：

- Design Token；
- Provider 摘要卡；
- Provider 紧凑行；
- 分类过滤；
- 设置页；
- 空状态、加载、错误和过期状态；
- Floating Widget；
- 深浅主题；
- 可访问性。

UI 不直接访问 Keychain 或网络。

### 7.3 菜单栏与 Panel 实现细节

建议：

- `LSUIElement = true`，默认不显示 Dock 图标；
- 使用 `NSStatusBar.system.statusItem` 创建菜单栏入口；
- 状态栏按钮使用模板图，正确适配深浅菜单栏；
- 自定义 `NSPanel` 子类允许成为 key window，保证键盘和输入框可用；
- Panel 无系统标题栏、背景透明、内容由 SwiftUI 承载；
- Panel 层级使用 floating，但不抢占其他应用的正常焦点；
- 点击状态栏按钮切换 Panel；
- 点击 Panel 外部关闭；
- 打开设置窗口时正常激活应用；
- Panel 根据状态栏按钮所在屏幕定位；
- 靠近屏幕边缘时调整箭头或内容方向；
- 屏幕、分辨率或缩放改变后重新计算位置；
- 全屏应用和多个 Space 中的行为需要单独验证；
- Panel 关闭时保留 View State，不重复创建所有 Provider；
- Panel 打开时从缓存立即渲染，再后台刷新。

不要使用普通 `NSPopover` 作为最终唯一实现，除非原型验证表明它可以满足：

- 键盘焦点；
- 复杂设置跳转；
- 自定义尺寸；
- 状态栏文字动态变化；
- 多显示器；
- Floating Widget 共用视图。

## 8. 核心数据模型

### 8.1 Provider 与账户

```swift
struct ProviderID: RawRepresentable, Hashable, Codable, Sendable {
    let rawValue: String
}

struct AccountID: RawRepresentable, Hashable, Codable, Sendable {
    let rawValue: UUID
}

struct ProviderAccount: Identifiable, Codable, Sendable {
    let id: AccountID
    let providerID: ProviderID
    var displayName: String
    var enabled: Bool
    var configuration: ProviderConfiguration
    var credentialReference: CredentialReference?
    var createdAt: Date
    var updatedAt: Date
}
```

注意：

- 账户 ID 由本应用生成，不能使用 email 作为主键；
- email、组织 ID 和 API Key ID 只能作为属性；
- 删除账户时必须同时删除 Keychain 凭据和非必要缓存；
- Provider 配置与密钥必须分开存储。

### 8.2 金额

```swift
struct Money: Hashable, Codable, Sendable {
    let amount: Decimal
    let currencyCode: String
}
```

规则：

- 金额禁止使用 `Double` 做累计；
- 使用 ISO 4217 币种代码，如 `CNY`、`USD`；
- 不自动把美元换成人民币，除非用户启用汇率换算；
- 原币种永远可以查看；
- 换算结果必须标记汇率时间和“估算”；
- 不把 New API 原始 quota 直接假设为美元。

### 8.3 额度窗口

```swift
struct QuotaWindow: Identifiable, Hashable, Codable, Sendable {
    let id: String
    let title: String
    let remainingRatio: Decimal?
    let used: Decimal?
    let limit: Decimal?
    let resetsAt: Date?
    let period: QuotaPeriod
}
```

规则：

- 内部统一保存 `remainingRatio`；
- UI 可以切换“已用”或“剩余”，但同一界面保持一致；
- 服务端只给 used ratio 时，在 Mapper 中转换；
- 不从本地 Token 猜测套餐 remaining ratio；
- reset 时间为空时显示未知，不自行推算；
- 所有时间内部使用 UTC。

### 8.4 用量

```swift
struct UsageSummary: Hashable, Codable, Sendable {
    let period: DateInterval
    let inputTokens: Int64?
    let outputTokens: Int64?
    let cachedInputTokens: Int64?
    let requestCount: Int64?
    let spend: Money?
    let isEstimated: Bool
}
```

规则：

- Token 采用 `Int64`；
- 不能把 cached tokens 丢进普通 input 后不加说明；
- Provider 不支持某字段时使用 `nil`，不是 `0`；
- `isEstimated` 必须贯穿到 UI；
- 官方成本和本地估算成本不能混合累计。

### 8.5 快照

```swift
struct ProviderSnapshot: Identifiable, Codable, Sendable {
    let id: SnapshotID
    let accountID: AccountID
    let providerID: ProviderID
    let identity: ProviderIdentity
    let balance: BalanceSummary?
    let quotaWindows: [QuotaWindow]
    let usage: [UsageSummary]
    let fetchedAt: Date
    let source: DataSourceDescriptor
    let freshness: Freshness
    let status: ProviderStatus
    let diagnostics: [Diagnostic]
}
```

快照中不保存：

- API Key；
- OAuth access token；
- Cookie；
- 完整请求 header；
- 原始网页 HTML；
- Prompt 或 Response 内容；
- 可恢复用户密钥的信息。

### 8.6 数据来源

```swift
enum DataSourceKind: String, Codable, Sendable {
    case officialAPI
    case compatibleAPI
    case oauth
    case localCLI
    case localLog
    case webSession
}

enum StabilityLevel: String, Codable, Sendable {
    case stable
    case compatible
    case local
    case experimental
}
```

UI 应允许用户查看来源和稳定等级。

### 8.7 Freshness

```swift
enum Freshness: Codable, Sendable {
    case fresh
    case refreshing(previousFetchedAt: Date)
    case stale(lastSuccessAt: Date)
    case expired(lastSuccessAt: Date)
    case unavailable
}
```

建议阈值：

| Provider 类型 | Fresh | Stale | Expired |
| --- | --- | --- | --- |
| 套餐额度 | 0-10 分钟 | 10-30 分钟 | 超过 30 分钟 |
| 余额 | 0-15 分钟 | 15-60 分钟 | 超过 60 分钟 |
| 组织成本 | 0-30 分钟 | 30 分钟-6 小时 | 超过 6 小时 |
| 本地日志 | 0-5 分钟 | 5-30 分钟 | 超过 30 分钟 |

这些值应可由 Provider metadata 覆盖。

## 9. Provider 协议

```swift
protocol UsageProvider: Sendable {
    var metadata: ProviderMetadata { get }

    func validate(
        account: ProviderAccount,
        credentials: ProviderCredentials,
        context: ProviderContext
    ) async throws -> ValidationResult

    func fetch(
        account: ProviderAccount,
        credentials: ProviderCredentials,
        context: ProviderContext
    ) async throws -> ProviderSnapshot
}
```

### 9.1 ProviderMetadata

应包含：

- Provider ID；
- 显示名称；
- 类别：API、套餐、中转、本地；
- 图标；
- 支持能力；
- 凭据类型；
- 默认刷新间隔；
- Freshness 阈值；
- 稳定等级；
- 文档 URL；
- 隐私说明；
- 最后验证日期；
- 支持的最低服务端版本。

### 9.2 能力声明

```swift
struct ProviderCapabilities: OptionSet, Sendable {
    let rawValue: UInt

    static let balance = Self(rawValue: 1 << 0)
    static let quotaWindows = Self(rawValue: 1 << 1)
    static let usage = Self(rawValue: 1 << 2)
    static let cost = Self(rawValue: 1 << 3)
    static let localHistory = Self(rawValue: 1 << 4)
    static let multipleAccounts = Self(rawValue: 1 << 5)
    static let manualRefresh = Self(rawValue: 1 << 6)
}
```

UI 根据能力选择组件，不根据 Provider 名称写分支。

例如：

- DeepSeek：`balance`；
- Codex：`quotaWindows`；
- OpenAI：`usage + cost`；
- New API：`balance + usage`；
- Claude：`quotaWindows + localHistory`；
- OpenRouter：`balance + cost`。

## 10. 数据流

```text
NSStatusItem / Settings / Timer
              |
              v
       RefreshCoordinator
              |
       AccountRepository
              |
       CredentialStore
              |
       ProviderRegistry
              |
       ProviderClient
              |
       Parser + Mapper
              |
      ProviderSnapshot
          /       \
         v         v
 SnapshotCache   HistoryStore
         \         /
          v       v
        AppStore actor
              |
              v
        SwiftUI Views
```

### 10.1 状态管理

使用单一 `actor AppStore` 或 `@MainActor Observable` presentation store：

- Domain 快照在 actor 内更新；
- UI 只消费不可变 View State；
- Provider 请求不能直接修改 UI；
- 设置保存失败时回滚本地 View State；
- 多账户刷新可以并行；
- 同一个 account 不能出现并发重复请求。

### 10.2 Presentation Mapping

增加独立 Presentation Mapper：

```text
ProviderSnapshot -> ProviderCardViewState
```

它负责：

- 选择主指标；
- 选择辅助指标；
- 格式化金额；
- 格式化 reset；
- 决定是否展示进度条；
- 生成状态文案；
- 选择状态色，但不选择 Provider 品牌色。

不要让 SwiftUI View 自己判断 OpenAI、DeepSeek 或 Codex。

## 11. 刷新与缓存

### 11.1 默认刷新间隔

| 数据源 | 默认间隔 |
| --- | --- |
| Codex/Claude 套餐 | 5 分钟 |
| DeepSeek/OpenRouter 余额 | 5 分钟 |
| New API/One API | 5 分钟 |
| OpenAI/Anthropic 组织成本 | 15 分钟 |
| 本地日志 | 文件变化 debounce 3 秒 |

当额度将在 15 分钟内重置时，可临时把套餐刷新间隔降到 1 分钟。

### 11.2 刷新触发

- 应用启动；
- Panel 打开；
- 用户手动刷新；
- 定时器；
- 网络从离线恢复；
- 系统从睡眠恢复；
- 账户配置变化；
- Keychain 凭据变化；
- 本地日志文件变化。

Panel 打开时先显示缓存，再刷新。禁止让用户盯着空白窗口等待网络。

### 11.3 并发

- 不同账户并行刷新，上限建议 3-4；
- 同一账户请求去重；
- 同一 Provider 可设置更低并发；
- 用户手动刷新可以提升优先级，但不能重复发起相同请求；
- 退出应用时取消未完成任务；
- 切换平台不应取消后台刷新。

### 11.4 退避

建议：

```text
第一次失败：30 秒
第二次失败：1 分钟
第三次失败：2 分钟
第四次失败：5 分钟
之后：最多 30 分钟
```

加入 10%-20% jitter。

429 优先使用：

- `Retry-After`；
- 服务商 rate-limit reset header；
- 响应中的 reset 时间。

### 11.5 缓存

缓存只保存最后成功归一化快照。

建议路径：

```text
~/Library/Caches/cool.nihility.miracledeck/snapshots/
```

要求：

- 每个账户独立文件；
- 文件名使用本应用 Account UUID；
- 有 schema version；
- 原子写入；
- 损坏时忽略并重建；
- 不把缓存同步到 iCloud；
- 不存凭据；
- 用户断开账户时删除缓存。

## 12. 多平台和多账户切换

### 12.1 三层入口

```text
菜单栏状态：看异常
      |
      v
总览列表：比较所有平台
      |
      v
摘要主卡：查看选中账户
```

### 12.2 菜单栏状态

支持三种模式：

1. 仅图标；
2. 固定一个指标；
3. 异常摘要。

默认使用异常摘要：

- 全部正常时只显示图标；
- 一个账户异常时显示 Provider 简称与数值；
- 多个账户异常时显示警告数量；
- Stale 不应被误判为额度耗尽。

菜单栏不默认自动轮播，避免用户不知道数字属于哪个平台。

### 12.3 Panel

推荐宽度：

```text
360-390pt
```

结构：

```text
Header
Category Filter
Selected Provider Hero
Provider Account List
Footer Freshness / Diagnostics
```

分类：

- 全部；
- API；
- 套餐；
- 中转；
- 本地。

Provider 少于 5 个时可以隐藏分类。

### 12.4 选择状态

- 使用 Account ID 保存选择，不使用列表下标；
- 删除当前账户后选择下一个可用账户；
- 过滤后当前账户不可见时，选择该分类第一个账户；
- 重启应用后恢复上次选择；
- 键盘方向键可以切换列表；
- `Return` 打开账户详情；
- `Command + R` 手动刷新；
- `Command + ,` 打开设置。

### 12.5 默认排序

1. Critical；
2. Warning；
3. 用户收藏；
4. 最近查看；
5. 用户自定义顺序；
6. 其他账户。

用户自定义顺序应优先于“最近查看”，异常账户可以临时提升但不修改持久顺序。

### 12.6 Hero 卡主指标选择

规则：

| 数据类型 | 主指标 |
| --- | --- |
| 套餐额度 | 最短有效窗口的剩余百分比 |
| 有余额 API | 可用余额 |
| 无余额但有费用 | 当前账期费用 |
| 中转站 | 剩余额度 |
| 本地日志 | 今日估算成本或 Token |

用户可以覆盖默认主指标。

## 13. UI 实施

### 13.1 设计系统

建立语义 Token：

```text
Color
Typography
Spacing
Radius
Shadow
Motion
Opacity
```

禁止在各个 View 中散落任意颜色和圆角。

### 13.2 核心组件

- `MonitorPanelView`
- `PanelHeader`
- `CategoryFilter`
- `ProviderHeroCard`
- `ProviderAccountList`
- `ProviderCompactRow`
- `PrimaryMetricView`
- `QuotaProgressView`
- `BalanceMetricView`
- `UsageMetricView`
- `ResetCountdownView`
- `FreshnessView`
- `SemanticStatusView`
- `ProviderMarkView`
- `CredentialStateView`
- `InlineDiagnosticView`
- `FloatingOrbView`
- `SettingsView`

### 13.3 视觉原则

- 一个 Hero 卡只有一个主数字；
- 只有明确上限的数据才用进度条；
- API 余额不用百分比颜色阈值；
- Provider 品牌色和健康状态色分离；
- 未知数据不显示为 0；
- 官方数据和估算数据使用明显标签；
- 使用系统字体；
- 使用统一图标家族；
- 重要内容不能只靠颜色表达；
- Aurora 只用于选中的 Hero 卡；
- 多账户列表保持静态；
- Panel 关闭时停止动画。

### 13.4 动效

允许：

- Panel 出现和消失；
- 选中 Provider 的淡入与轻微位移；
- 进度条数值变化；
- Hero 背景非常慢的 Aurora；
- Floating Widget 展开和收起；
- 错误状态切换。

禁止：

- 卡片翻转；
- 自动快速轮播；
- 所有列表项持续发光；
- 大幅缩放；
- 背景动画影响文字区域；
- 菜单关闭后继续运行动画。

所有动效必须支持 `accessibilityReduceMotion`。

### 13.5 深色与高对比

首个 UI 原型必须同时设计：

- Light；
- Dark；
- Increased Contrast；
- Reduce Transparency；
- Reduce Motion。

不要先完成浅色版，再在发布前临时反色。

## 14. Provider 实施顺序

### 14.1 Mock Provider

目的：

- 验证所有状态；
- 构建 UI Preview；
- 不依赖真实凭据；
- 支持截图和视觉回归。

Fixtures：

- Healthy；
- Warning；
- Critical；
- Loading；
- Refreshing；
- Stale；
- Expired；
- Signed out；
- Permission denied；
- Rate limited；
- Format changed；
- Multi-currency；
- No data。

### 14.2 DeepSeek Provider

验证：

- 官方 API；
- API Key；
- 多币种；
- Balance 卡；
- Keychain；
- 401/429；
- 余额不可用。

验收：

- 正确显示 `CNY` 和 `USD`；
- 正确区分赠送与充值余额；
- 不把余额差值称为 Token；
- 不记录 API Key；
- Fixture 覆盖字段缺失和字符串金额。

### 14.3 New API Provider

验证：

- 自定义 base URL；
- 控制台 Access Token；
- `New-Api-User`；
- quota 单位；
- 第三方兼容差异；
- 多账户；
- SSRF 和 URL 校验。

验收：

- `/api/user/self` 正常解析；
- `/api/log/self/stat` 可选解析；
- 不能用模型调用 Key 时给出明确说明；
- 换算率不可硬编码；
- HTTPS 默认要求；
- localhost 允许 HTTP；
- 响应大小有限制；
- 站点返回 HTML 时有明确错误。

### 14.4 Codex Provider

建议数据源顺序：

1. Codex OAuth；
2. `codex app-server`；
3. 本地日志只用于估算成本；
4. 网页数据后置为实验功能。

验收：

- 读取 5 小时与周额度；
- 显示 reset；
- 识别套餐；
- 不修改 OAuth 文件；
- CLI 子进程有超时；
- 不通过 shell 启动；
- 正确终止子进程；
- 多账户凭据隔离；
- 非公开数据源显示 Experimental。

### 14.5 OpenAI Provider

验收：

- 明确要求 Organization Admin Key；
- 普通 Project Key 权限不足时给出说明；
- 成本与 Usage 分开解析；
- 分页正确；
- 时间范围正确；
- 支持可选 Project ID；
- 不依赖旧 credit grants 作为主路径。

### 14.6 OpenRouter Provider

验收：

- Management Key 权限说明；
- total credits 与 total usage 精度正确；
- 余额使用 Decimal；
- 403 与普通 API Key 错误说明清楚。

### 14.7 Claude Provider

建议数据源顺序：

1. Claude OAuth usage；
2. Claude CLI `/usage`；
3. Web Cookie 为实验性回退；
4. 本地日志只用于估算成本。

验收：

- 5 小时、7 天和模型窗口；
- extra usage；
- OAuth scope 错误；
- CLI PTY 超时和退出；
- 不产生用户项目垃圾日志；
- Cookie 功能默认关闭；
- 不把本地 Token 转为套餐额度。

### 14.8 Anthropic Provider

验收：

- Admin Key；
- Usage API；
- Cost API；
- 分页；
- cache read/create Token；
- 个人账户不支持时给出明确说明；
- 与 Claude 套餐账户在 UI 中明确分开。

### 14.9 LiteLLM Provider

LiteLLM 放在 v0.4，不阻塞首个公开 Beta。

原因：

- 部署版本和管理 API 差异较大；
- 用户可能只有 Virtual Key，也可能持有 Master Key；
- spend、budget、user、team 和 key 的权限边界复杂；
- 自托管地址带来额外的 URL 安全要求。

验收：

- 明确支持的最低 LiteLLM 版本；
- 优先使用只读或最小权限凭据；
- 支持 key spend 与 budget；
- 可选支持 user/team spend；
- Master Key 必须有高权限警告；
- 不读取或展示其他用户的秘密；
- 对无数据库模式和不同部署模式有明确限制；
- Fixture 覆盖至少两个受支持版本；
- 不允许跨域重定向泄露 Authorization；
- 响应日志经过脱敏。

## 15. 凭据与安全

### 15.1 Keychain

Keychain item 建议：

```text
service: cool.nihility.miracledeck.<providerID>
account: <Account UUID>
label: MiracleDeck - <Provider> - <Account Name>
```

要求：

- 添加凭据前先验证；
- 验证失败不覆盖旧凭据；
- 更新采用 `SecItemUpdate`；
- 删除账户同步 `SecItemDelete`；
- 不使用 UserDefaults 存密钥；
- 不把密钥放进 crash report；
- 不把密钥传到剪贴板，除非用户明确操作；
- Keychain 失败必须有可理解错误。

### 15.2 最小权限

- OpenAI 只在需要组织数据时要求 Admin Key；
- OpenRouter 明确解释 Management Key 权限；
- New API 使用只读控制台 Token；
- 不要求用户输入账户密码；
- Cookie 方案默认关闭；
- 不为读取额度申请无关权限。

### 15.3 日志脱敏

必须屏蔽：

- `Authorization`；
- Bearer Token；
- `x-api-key`；
- Cookie；
- `sk-` 开头的密钥；
- JWT；
- URL query token；
- 用户 home 路径；
- email 可由用户选择是否包含；
- 组织 ID 和 Project ID 默认部分遮罩。

所有 Provider 错误进入日志前先通过 `Redactor`。

### 15.4 网络安全

- 默认只允许 HTTPS；
- `localhost`、`127.0.0.1` 和 `::1` 可以使用 HTTP；
- 不提供忽略证书错误开关；
- 不自动跟随跨域重定向携带凭据；
- 重定向后必须重新验证目标；
- 限制响应大小；
- 设置连接和总请求超时；
- 自定义 Provider 必须防止 SSRF；
- 禁止访问 link-local 和云 metadata 地址；
- 自定义 Header 名称使用 allowlist 或明确警告；
- User-Agent 中包含项目名称、版本和项目 URL。

### 15.5 App Sandbox 决策

读取 `~/.codex`、`~/.claude` 和其他应用本地数据与 App Sandbox 存在冲突。

v0.x 建议：

- 使用 Developer ID 直接分发；
- 开启 Hardened Runtime；
- 暂不启用 App Sandbox；
- 所有文件读取保持只读；
- 文档明确列出访问路径；
- 不申请 Full Disk Access；
- CLI 和日志路径允许用户关闭；
- 未来单独评估 sandboxed build。

如果未来进入 Mac App Store，需要改为：

- 用户选择目录；
- Security-scoped bookmark；
- 或受控 helper；
- 重新评估 OAuth 和 CLI 子进程。

不要在没有架构评估的情况下同时承诺 Mac App Store 和自动读取本地 CLI 凭据。

## 16. 隐私

项目默认 Local First：

- 密钥只保存在本机 Keychain；
- 应用直连用户配置的服务商；
- 项目不运营中间服务器；
- 不上传 Prompt、Response 或聊天记录；
- 不默认启用 Telemetry；
- 不默认启用 Crash Reporting；
- 不上传 Provider 原始响应；
- 不上传账户列表；
- 不跨设备同步密钥。

需要编写 `PRIVACY.md`，逐项列出：

- 每个 Provider 访问的域名；
- 使用的凭据；
- 读取的本地路径；
- 保存的数据；
- 数据保留时间；
- 如何删除；
- 哪些功能属于 Experimental；
- 是否有第三方更新或诊断服务。

如果以后加入匿名统计，必须：

- 默认关闭或明确 opt-in；
- 不包含账户 ID、域名、余额、费用、Token 或错误响应；
- 可以在设置中查看和关闭；
- 文档公开事件 schema。

## 17. 设置设计

### 17.1 General

- 登录时启动；
- 菜单栏显示模式；
- 刷新间隔；
- 语言；
- 主题；
- “已用/剩余”显示；
- 通知开关；
- Floating Widget；
- 全局快捷键。

### 17.2 Accounts

- 添加账户；
- Provider 分类；
- 账户名称；
- 连接状态；
- 数据来源；
- 稳定等级；
- 最近成功刷新；
- 修改凭据；
- 测试连接；
- 断开账户；
- 删除账户；
- 排序与收藏。

### 17.3 Notifications

- 套餐剩余阈值；
- 余额阈值；
- 预算阈值；
- 数据恢复；
- reset 完成；
- 勿扰时间；
- 每个账户单独开关。

### 17.4 Advanced

- 代理；
- Provider 诊断；
- 缓存清理；
- 配置导出；
- Experimental 数据源；
- 本地日志扫描；
- 数据路径；
- 更新通道；
- 开发者日志。

高级功能不能混进首次添加账户的主流程。

## 18. 通知策略

通知必须克制。

默认只通知：

- 套餐剩余低于 20%；
- 套餐剩余低于 10%；
- 余额低于用户设置金额；
- Provider 从不可用恢复；
- 用户明确订阅的 reset 完成。

避免：

- 每次刷新通知；
- 相同阈值重复通知；
- Stale 立即通知；
- 所有 API 错误都通知；
- 应用启动时集中补发过期通知。

去重键：

```text
accountID + metricID + threshold + resetWindowID
```

同一窗口同一阈值只通知一次。

## 19. 本地日志和成本估算

本地日志功能必须晚于官方数据路径。

### 19.1 数据边界

- 只读取 Token 和模型元数据；
- 不解析或保存 Prompt/Response 内容；
- 不复制完整 JSONL；
- 只缓存聚合结果；
- 增量扫描；
- 支持用户完全关闭；
- UI 始终显示“本地估算”。

### 19.2 价格表

价格记录需要：

- Provider；
- Model ID；
- 生效时间；
- input；
- output；
- cache read；
- cache write；
- currency；
- source URL；
- last verified。

价格变化后：

- 新请求使用新价格；
- 历史重新计算必须明确提示；
- 无法确定历史生效价时标记估算；
- 未知模型不猜价格。

### 19.3 扫描性能

- 文件索引缓存；
- 根据 modification date 增量更新；
- 大文件流式解析；
- 不一次性加载所有 JSONL；
- 文件变化 debounce；
- 后台低优先级；
- 扫描取消；
- 每次扫描设置时间预算；
- 避免跟随符号链接进入无限目录。

## 20. 历史存储

v0.2 前只保存最后快照。需要趋势时再引入 SQLite。

建议表：

```text
accounts
provider_snapshots
quota_samples
balance_samples
usage_daily
notification_events
schema_migrations
```

历史数据原则：

- 不保存秘密；
- 不保存 Prompt/Response；
- 允许按账户删除；
- 允许设置保留天数；
- 默认保留 90 天；
- 提供“清除所有历史”；
- 数据库迁移有测试；
- 写入失败不影响当前快照展示；
- 金额使用 decimal string 或 integer minor unit，不使用浮点。

## 21. 错误模型

```swift
enum ProviderError: Error, Sendable {
    case noCredentials
    case invalidCredentials
    case insufficientPermissions
    case signedOut
    case rateLimited(retryAt: Date?)
    case networkUnavailable
    case timeout
    case server(statusCode: Int)
    case unsupportedAccount
    case incompatibleServerVersion
    case responseTooLarge
    case invalidResponse
    case formatChanged
    case localResourceUnavailable
    case cancelled
}
```

用户文案必须回答：

1. 发生了什么；
2. 数据是否仍可信；
3. 应用会不会自动重试；
4. 用户需要做什么；
5. 是否可以复制诊断。

不要直接向普通用户显示 Rust、Swift、JSON decoding 或 HTTP client 的底层报错。

## 22. 测试计划

### 22.1 单元测试

覆盖：

- 金额精度；
- 时间格式；
- reset 计算；
- used/remaining 转换；
- Freshness；
- 状态阈值；
- 排序；
- 通知去重；
- 脱敏；
- 配置迁移；
- View State 映射。

### 22.2 Provider Fixture 测试

每个 Provider 必须有：

- 正常响应；
- 空响应；
- 缺失字段；
- 未知字段；
- 字符串和数字混合；
- 多币种；
- 超大 Token；
- 401；
- 403；
- 404；
- 429；
- 500；
- HTML 错误页；
- 无效 JSON；
- 响应格式变化；
- 分页；
- 超时；
- 取消。

Fixture 必须脱敏，禁止提交真实 Token、Cookie、账户 ID 和 email。

### 22.3 网络测试

使用自定义 `URLProtocol` 或注入 HTTP Transport：

- 验证 Header；
- 验证 Query；
- 验证分页；
- 验证 Retry-After；
- 验证跨域重定向不泄露凭据；
- 验证超时；
- 验证响应大小限制；
- 验证代理配置。

### 22.4 持久化测试

- Keychain add/update/delete；
- Keychain 重复项；
- 配置损坏恢复；
- 原子写；
- Schema 升级；
- Schema 降级提示；
- 缓存损坏；
- 删除账户清理；
- 多账户隔离。

CI 中不操作真实用户 Keychain。使用 abstraction 和临时 Keychain 或 Mock。

### 22.5 UI 测试

覆盖：

- Panel 打开和关闭；
- Provider 切换；
- 分类过滤；
- 空账户；
- 添加账户；
- 凭据错误；
- Stale；
- 多账户；
- 深色；
- Dynamic Type；
- 键盘操作；
- VoiceOver 标签；
- Reduce Motion；
- High Contrast。

### 22.6 视觉回归

固定 Mock 数据生成截图：

- Light/Dark；
- Healthy/Warning/Critical；
- Balance/Quota/Cost；
- Stale/Error/Signed out；
- 1、5、20 个账户；
- 中英文；
- 长 Provider 名称；
- 大金额；
- 小窗口；
- Floating Orb。

### 22.7 Live Contract Tests

真实接口测试只能手动 opt-in：

- 从环境变量读取测试凭据；
- 不在公共 CI 执行；
- 不输出原始响应；
- 记录 Provider 版本和验证日期；
- 测试后可生成脱敏 fixture；
- 不允许测试产生计费请求，除非明确批准。

## 23. 性能预算

目标：

| 指标 | 目标 |
| --- | --- |
| 从缓存打开 Panel | 150ms 内可见 |
| 冷启动到菜单栏出现 | 1 秒内 |
| 空闲 CPU | 通常低于 0.5% |
| Panel 关闭时 CPU | 接近 0% |
| 空闲内存 | 目标低于 70MB |
| 后台刷新并发 | 最多 4 |
| Provider 响应上限 | 默认 5MB，可按 Provider 降低 |
| 普通请求超时 | 10-15 秒 |
| CLI Probe 超时 | 15-30 秒 |
| 动画 | 只使用 transform、opacity 或原生材质 |

性能测试应包含：

- 20 个账户；
- 大型 Codex/Claude 日志；
- 网络离线；
- 服务商持续 429；
- 从睡眠恢复；
- 多显示器；
- 低电量模式；
- Panel 连续打开关闭；
- 24 小时常驻。

## 24. 可访问性

必须支持：

- VoiceOver；
- 键盘完整操作；
- 可见焦点；
- Reduce Motion；
- Reduce Transparency；
- Increase Contrast；
- Dynamic Type 或可接受的 macOS 字号缩放；
- 非颜色状态；
- 英文和中文布局；
- 菜单栏图标可访问名称；
- 图表和进度条的语义值。

注意：

- 小型控制的视觉尺寸可以是 26-30pt，但命中区域应尽量达到 36pt；
- Tooltip 不能是唯一说明；
- `%`、币种和 reset 要有完整 VoiceOver 文案；
- 图标按钮必须有 accessibility label；
- Aurora 背景不能降低文字对比度。

## 25. 国际化

首版：

- `zh-Hans`；
- `en`。

使用 String Catalog。

注意：

- 不拼接翻译句子；
- 相对时间使用系统格式；
- 金额使用 `FormatStyle.Currency`；
- Provider 返回的错误不要直接当翻译文案；
- 日期、周起始和时区跟随系统；
- reset 同时提供相对和绝对时间；
- Provider 名和模型名不翻译；
- 中文布局不能使用过宽字距。

## 26. 发布工程

### 26.1 CI

PR 必须执行：

- Swift format check；
- Swift lint；
- build；
- unit tests；
- Provider fixture tests；
- UI smoke tests；
- secret scan；
- license scan；
- 文档链接检查。

Release tag 执行：

- Release build；
- universal archive；
- 签名；
- notarization；
- Sparkle 签名；
- DMG；
- SHA-256；
- SBOM；
- GitHub Release；
- appcast 更新。

### 26.2 分支与版本

建议：

```text
main              始终可发布
feature/*         功能分支
fix/*             修复分支
release/*         必要时使用
```

版本遵循 SemVer：

```text
0.1.0-alpha.1
0.2.0-beta.1
1.0.0
```

### 26.3 自动更新

- Stable 与 Beta 两个 channel；
- 更新前保留配置备份；
- 新版本第一次启动执行迁移；
- 迁移失败时停止写入并提示；
- Sparkle 私钥只能存 CI Secret；
- 不把签名私钥提交仓库；
- 更新包必须签名和 HTTPS。

## 27. 开源仓库建设

Phase 0 应补齐：

```text
LICENSE
NOTICE
PRIVACY.md
SECURITY.md
CONTRIBUTING.md
CODE_OF_CONDUCT.md
CHANGELOG.md
SUPPORT.md
.github/ISSUE_TEMPLATE/
.github/PULL_REQUEST_TEMPLATE.md
.github/workflows/
docs/provider-support.md
docs/architecture.md
docs/privacy-boundaries.md
```

### 27.1 Provider 支持矩阵

每个 Provider 记录：

- 功能；
- 数据来源；
- 凭据；
- 稳定等级；
- 最后验证日期；
- 已知限制；
- 支持的账户类型；
- 支持的服务端版本；
- 维护者；
- 测试 fixture。

### 27.2 贡献 Provider 的门槛

PR 必须包含：

- Provider metadata；
- 实现；
- 正常 fixture；
- 错误 fixture；
- 单元测试；
- 隐私说明；
- 官方或项目文档链接；
- 脱敏确认；
- 支持矩阵更新；
- UI 截图；
- 不引入 shell 脚本执行。

### 27.3 依赖策略

首版尽量少依赖：

- 系统 Security framework；
- Foundation URLSession；
- SwiftUI/AppKit；
- Sparkle 仅用于更新；
- 格式化和 lint 工具作为开发依赖；
- SQLite 依赖在 v0.2 单独评估。

每个运行时依赖必须说明：

- 为什么需要；
- 许可证；
- 维护状态；
- 包体影响；
- 安全风险；
- 是否可以用系统 API 替代。

## 28. 里程碑任务清单

### M0：仓库与工程

- [x] 安装完整 Xcode；
- [x] 初始化 Git；
- [x] 创建 Xcode App；
- [x] 设置 macOS 14 deployment target；
- [x] 设置 Swift 6 strict concurrency；
- [x] 创建本地 Packages；
- [x] 创建 CI；
- [x] 添加 LICENSE、SECURITY、PRIVACY；
- [ ] 添加代码格式化；
- [x] 添加基础测试；
- [x] 确定 Bundle ID 为 `cool.nihility.miracledeck`。

验收：空应用可以在干净机器构建，CI 通过。

### M1：菜单栏外壳

- [ ] NSStatusItem；
- [ ] NSPanel；
- [ ] Panel 锚定状态栏；
- [ ] 点击外部关闭；
- [ ] 多显示器定位；
- [ ] 设置窗口；
- [ ] Mock Provider；
- [ ] 浅色/深色；
- [ ] 菜单栏图标；
- [ ] 缓存数据立即展示。

验收：点击菜单栏 150ms 内看到 Mock 数据。

### M2：核心框架

- [ ] Domain 模型；
- [ ] Provider 协议；
- [ ] Provider Registry；
- [ ] Account Repository；
- [ ] Credential Store；
- [ ] Snapshot Cache；
- [ ] Refresh Coordinator；
- [ ] Error Mapping；
- [ ] Redactor；
- [ ] Presentation Mapper；
- [ ] Provider fixture harness。

验收：Mock Provider 可以通过真实刷新链路进入 UI。

### M3：DeepSeek

- [ ] 添加账户；
- [ ] Keychain；
- [ ] Balance API；
- [ ] 多币种；
- [ ] 错误状态；
- [ ] 手动刷新；
- [ ] 定时刷新；
- [ ] Fixture tests。

验收：真实 DeepSeek Key 可稳定工作，日志中无密钥。

### M4：New API

- [ ] Base URL；
- [ ] 控制台 Token；
- [ ] User ID；
- [ ] `/api/user/self`；
- [ ] `/api/log/self/stat`；
- [ ] 单位配置；
- [ ] 多站点；
- [ ] URL 安全；
- [ ] 兼容错误；
- [ ] Fixture tests。

验收：至少验证两个不同部署或 fork。

### M5：Codex

- [ ] OAuth 凭据读取；
- [ ] app-server fallback；
- [ ] quota windows；
- [ ] credits；
- [ ] reset；
- [ ] account identity；
- [ ] 多账户；
- [ ] CLI timeout；
- [ ] Experimental 标识；
- [ ] Fixture tests。

验收：套餐数据与 Codex 自身显示一致，失败时不伪造。

### M6：多平台 UX

- [ ] 分类过滤；
- [ ] Hero + List；
- [ ] 排序；
- [ ] 收藏；
- [ ] 最近选择；
- [ ] 菜单栏异常摘要；
- [ ] 键盘导航；
- [ ] 中英文；
- [ ] 空状态；
- [ ] 添加账户流程。

验收：20 个账户仍可快速切换并理解来源。

### M7：OpenAI 与 OpenRouter

- [ ] OpenAI Admin Key；
- [ ] Usage；
- [ ] Costs；
- [ ] 分页；
- [ ] Project filter；
- [ ] OpenRouter Management Key；
- [ ] Credits；
- [ ] 权限说明；
- [ ] Fixture tests。

验收：组织数据、余额和普通 Key 权限错误均正确展示。

### M8：Claude 与 Anthropic

- [ ] Claude OAuth；
- [ ] Claude CLI fallback；
- [ ] quota windows；
- [ ] extra usage；
- [ ] Anthropic Admin API；
- [ ] usage/cost；
- [ ] 套餐与 API 账户分离；
- [ ] Experimental Cookie 开关；
- [ ] Fixture tests。

验收：Claude 套餐和 Anthropic API 不会混为同一账户。

### M9：设置、通知和诊断

- [ ] General；
- [ ] Accounts；
- [ ] Notifications；
- [ ] Advanced；
- [ ] 通知去重；
- [ ] 脱敏诊断；
- [ ] 缓存清理；
- [ ] 登录时启动；
- [ ] 更新通道。

验收：普通错误可自助修复，高级诊断不泄露秘密。

### M10：Floating Widget

- [ ] Orb；
- [ ] Provider 身份；
- [ ] 展开/收起；
- [ ] 点击固定；
- [ ] 屏幕边缘；
- [ ] 多显示器；
- [ ] 静态空闲背景；
- [ ] Reduce Motion；
- [ ] 可关闭。

验收：不影响菜单栏主流程，空闲 CPU 接近 0%。

### M11：Beta 发布

- [ ] 签名；
- [ ] notarization；
- [ ] Sparkle；
- [ ] DMG；
- [ ] Homebrew Cask；
- [ ] Privacy；
- [ ] Security；
- [ ] Provider matrix；
- [ ] 用户文档；
- [ ] 崩溃和性能测试；
- [ ] 24 小时常驻测试；
- [ ] 升级和迁移测试。

验收：非开发者可以安全安装、配置、升级和卸载。

### M12：v0.3 本地历史

- [ ] Claude Code 增量扫描；
- [ ] Codex 增量扫描；
- [ ] SQLite schema；
- [ ] 历史迁移；
- [ ] 价格表；
- [ ] Today/Yesterday/7d/30d；
- [ ] Estimated 标签；
- [ ] 历史清理；
- [ ] 大日志性能测试；
- [ ] 未知模型处理。

验收：本地日志不会读取或保存对话内容，历史估算不会与官方账单混合。

### M13：v0.4 开放扩展

- [ ] LiteLLM Provider；
- [ ] Custom HTTP Provider；
- [ ] URL 与 SSRF 防护；
- [ ] Provider manifest；
- [ ] Fixture 验证工具；
- [ ] 配置导入导出；
- [ ] localhost 只读 API；
- [ ] CLI JSON 输出；
- [ ] 社区 Provider 模板；
- [ ] 扩展文档。

验收：扩展能力不执行任意代码，不允许通过配置泄露其他 Provider 凭据。

### M14：v1.0

- [ ] 冻结首版 Domain schema；
- [ ] 冻结 Provider contract；
- [ ] 处理全部高优先级 Beta 问题；
- [ ] 完成升级和回滚测试；
- [ ] 完成隐私与安全审计；
- [ ] 完成性能预算验收；
- [ ] 完成可访问性验收；
- [ ] 完成中英文文档；
- [ ] 发布 Stable channel；
- [ ] 制定 v1.1 路线。

验收：满足第 6.6 节的全部稳定承诺。

## 29. 每阶段 Definition of Done

任何功能只有同时满足以下条件才算完成：

- 功能实现；
- 正常和错误路径测试；
- 不泄露凭据；
- 中英文文案；
- 深色模式；
- 可访问性标签；
- Reduce Motion；
- 文档更新；
- 支持矩阵更新；
- 无新增高优先级警告；
- 性能没有明显退化；
- 至少一个真实环境手动验证；
- 失败时保留最后可信数据或明确显示不可用。

“接口能返回数据”不等于 Provider 完成。

## 30. 风险清单

| 风险 | 影响 | 应对 |
| --- | --- | --- |
| 非公开套餐接口变化 | Provider 突然失效 | 多数据源回退、Experimental 标识、fixture、last verified |
| New API fork 差异 | 字段和单位不一致 | 强类型标准 adapter + 可配置换算 + 兼容 fixture |
| Admin Key 权限过高 | 密钥泄露影响大 | Keychain、最小权限说明、日志脱敏、不上传 |
| App Sandbox 冲突 | 无法读 CLI 凭据和日志 | v0.x 直接分发、Hardened Runtime、只读边界 |
| Keychain 反复弹窗 | 用户体验差 | 缓存凭据引用、只在用户操作时提示、错误指导 |
| 多账户刷新耗电 | 常驻资源占用上升 | 并发限制、低频刷新、Panel 关闭停止动画 |
| 金额精度错误 | 误导账单 | Decimal、Fixture、小数与币种测试 |
| 时间与 reset 错误 | 用户错判恢复时间 | UTC 存储、系统时区显示、相对+绝对时间 |
| 本地日志估算不准 | 用户误认官方账单 | 明确 Estimated、分开汇总、不猜未知价格 |
| Provider 图标版权 | 发布和商标风险 | 使用允许资产、注明商标归属、支持用户自定义 |
| 自动更新供应链 | 安装恶意版本 | Sparkle 签名、CI 最小权限、保护 release secret |
| 自定义 URL SSRF | 访问本机或内网敏感地址 | v0.4 后置、URL 校验、阻止 metadata、明确警告 |
| 响应体过大 | 内存或磁盘问题 | 响应上限、流式解析、超限错误 |
| 真实账户难测试 | 兼容问题发现晚 | Public Beta、手动 contract tests、脱敏 fixture |
| 项目范围膨胀 | 长期无法发布 | 严格版本范围，Provider 新增不阻塞核心发布 |

## 31. 特别注意事项

### 31.1 API 与套餐必须分开

以下是不同产品：

- OpenAI API；
- ChatGPT/Codex 套餐；
- Anthropic API；
- Claude Pro/Max/Team。

UI、设置和文档必须使用不同账户类型，不允许只写一个“OpenAI”或“Claude”后混合数据。

### 31.2 余额、预算和额度不是同一概念

- 余额：账户还可以消费的钱；
- 预算：用户自己设定的上限；
- 套餐额度：服务商定义的使用窗口；
- Rate limit：请求频率和 Token 速率限制；
- 本地 Token：本机记录的历史用量。

它们需要不同组件和文案。

### 31.3 未知不等于零

任何字段缺失、解析失败或权限不足都显示：

- 未知；
- 暂不可用；
- 权限不足；
- 数据已过期。

禁止显示 `0`、`0%` 或 `$0`。

### 31.4 估算必须显式

以下数据通常是估算：

- 本地日志计算的费用；
- 余额差值推断的消费；
- 汇率换算；
- 无法确定历史价格的成本；
- 根据采样推算的耗尽时间。

必须使用“估算”标签和说明。

### 31.5 不把 Provider 维护成本藏起来

每个 Provider 是一个长期维护承诺。

新增 Provider 前必须回答：

- 是否有公开文档；
- 是否有合法稳定的认证方式；
- 是否能获得脱敏 fixture；
- 是否有人维护；
- 接口失效时如何降级；
- 是否值得增加设置和支持成本。

### 31.6 不为了功能覆盖牺牲轻量

- 不引入 Electron；
- 不在后台加载隐藏 WebView，除非用户启用实验功能；
- 不让所有卡片播放动画；
- 不每分钟刷新所有组织成本；
- 不持续扫描完整日志目录；
- 不在菜单栏文字中自动轮播。

### 31.7 不复制参考项目的完整设计

可以借鉴 Quota Float 的：

- 信息层级；
- 状态语义；
- Orb 概念；
- 柔和环境色。

但需要重新设计：

- 多 Provider 信息架构；
- 颜色 Token；
- 组件尺寸；
- Provider 列表；
- 深色模式；
- 图标与品牌。

### 31.8 不在首版做 Custom Provider 脚本

自定义 Provider 最多允许声明式 GET + JSON 路径映射。

禁止：

- JavaScript；
- Shell；
- Python；
- 任意可执行文件；
- 动态下载插件；
- 绕过 TLS。

## 32. 开发工作方式

### 每个 Provider 的开发流程

1. 核对官方或项目文档；
2. 写 Provider metadata；
3. 收集并脱敏 fixture；
4. 先写 Parser 测试；
5. 再写 HTTP Client 测试；
6. 实现 Mapper；
7. 接入 Mock Credential Store；
8. 实现真实凭据；
9. 接入 Refresh Coordinator；
10. 接入 UI；
11. 验证错误和 Stale；
12. 真实账户手动测试；
13. 更新支持矩阵和隐私文档。

### 每个 UI 功能的开发流程

1. Mock View State；
2. Light/Dark Preview；
3. Loading/Empty/Error/Stale；
4. 键盘与 VoiceOver；
5. Reduce Motion/Transparency；
6. 长文本和中文；
7. 性能检查；
8. 视觉回归截图；
9. 接入真实 AppStore。

## 33. 项目成功指标

v1.0 建议使用以下指标判断是否成功：

- 配置一个账户不超过 2 分钟；
- Panel 从缓存打开不超过 150ms；
- 用户一眼能识别异常账户；
- 余额、套餐和估算不会混淆；
- 常驻 24 小时无明显资源泄漏；
- 主要 Provider 一个月内兼容性问题可追踪；
- 用户可以安全导出脱敏诊断；
- 删除账户后相关凭据和缓存被清理；
- 不需要项目自己的云端服务；
- 社区可以只修改 Provider Package 添加新平台。

## 34. 开发开始前的最终检查

- [x] 项目名称和 Bundle ID 已确定；
- [x] Xcode 完整安装；
- [x] Git 仓库初始化；
- [ ] Apple Developer 账号可用；
- [ ] MIT License 已确认；
- [ ] App Sandbox 策略已确认；
- [ ] macOS 14 最低版本已确认；
- [ ] 设计 Token 已冻结第一版；
- [ ] Domain 模型评审完成；
- [ ] Provider 协议评审完成；
- [ ] DeepSeek、New API、Codex 测试账户可用；
- [ ] 所有测试凭据不会进入仓库；
- [ ] CI secret 权限最小化；
- [ ] Privacy 和 Security 初稿存在；
- [ ] v0.1 范围不再增加 Provider。

## 35. 推荐的第一批实际开发任务

按以下顺序开始：

1. 初始化 Git 和 Xcode 工程；
2. 创建 `MiracleDeckCore`、`MiracleDeckProviders`、`MiracleDeckUI`；
3. 定义 `Money`、`QuotaWindow`、`UsageSummary`、`ProviderSnapshot`；
4. 定义 `UsageProvider` 和 `ProviderMetadata`；
5. 实现 Mock Provider 和所有状态 fixture；
6. 实现 NSStatusItem + NSPanel；
7. 完成 Hero + Provider List 原型；
8. 实现 Account Repository；
9. 实现 Keychain Credential Store；
10. 实现 Snapshot Cache；
11. 实现 Refresh Coordinator；
12. 接入 DeepSeek；
13. 接入 New API；
14. 接入 Codex；
15. 完成 v0.1 Alpha 验收。

在第 15 步以前，不增加新的 Provider，不实现历史图表，不实现 Custom HTTP，不实现 Windows 版本。
