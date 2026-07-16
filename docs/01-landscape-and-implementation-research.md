# MiracleDeck：同类项目与实现方案调研

> 调研日期：2026-07-15
> 目标平台：首选 macOS 菜单栏；未来可复用核心层到 Windows/Linux 版本。
> 注意：服务商接口、套餐规则和非公开网页接口变化很快，本文中的链接和可行性需要在实现时再次验证。

## 1. 结论先行

这个方向已经被市场验证，并且有几个成熟的开源项目，但仍有可做的差异化空间。

最接近目标的是 [CodexBar](https://github.com/steipete/CodexBar)：MIT 许可、原生 macOS、覆盖大量 AI 服务商，同时处理套餐额度、API 花费、本地日志、OAuth、Cookie 和 CLI 数据。它几乎可以作为本项目的“实现百科”。[OpenUsage](https://github.com/robinebers/openusage) 的插件模型、统一数据结构、缓存和本地 HTTP API也非常值得参考。

现有产品主要集中在 Claude/Codex/Cursor 等“编程订阅额度”。对中国用户常见的 DeepSeek 官方 API、New API/One API 中转站、多站点余额聚合，以及“API 账户”和“套餐账户”同时展示，支持通常不够完整。这可以成为本项目的核心定位：

> 一个隐私优先、原生轻量、对国内外官方 API 与中转站同等友好的菜单栏额度卡片。

推荐从原生 Swift 6 + SwiftUI/AppKit 开始，不建议首版使用 Electron。数据采集采用 provider 插件架构，并把数据源明确分为三类：

1. **官方公开 API**：最稳定，首选；
2. **本地凭据/CLI/日志**：隐私好、通常稳定，但只能代表本机；
3. **网页 Cookie 或非公开接口**：能拿到套餐额度，但最易失效，必须显式标注为“实验性”。

首版不要追求几十家 provider。建议先完成 OpenAI API、DeepSeek API、OpenRouter、New API/One API、Codex 套餐、Claude 套餐六类数据源，把插件协议、凭据安全、缓存和错误体验打磨好。

## 2. 同类开源项目

以下活跃度为调研时快照，不应写进产品逻辑或长期宣传材料。

| 项目 | 形态与技术 | 覆盖重点 | 值得复用的思路 | 许可/备注 |
| --- | --- | --- | --- | --- |
| [CodexBar](https://github.com/steipete/CodexBar) | macOS 菜单栏；Swift/SwiftUI | Codex、Claude、OpenAI API、DeepSeek、OpenRouter、LiteLLM 等大量 provider | 多数据源回退、OAuth/CLI/网页组合、统一快照、本地日志成本、诊断导出、签名发布 | MIT；调研时约 18.3k stars，是最重要的参考项目 |
| [OpenUsage](https://github.com/robinebers/openusage) | macOS 菜单栏；Swift 6、SwiftUI + AppKit | Claude、Codex、Cursor、Copilot、OpenRouter 等订阅额度 | `ProviderRuntime` 小协议、标准化 snapshot、stale-while-revalidate、5 分钟缓存、CLI 和 localhost API 共用核心层 | MIT；macOS 15+ |
| [ClaudeBar](https://github.com/tddworks/ClaudeBar) | macOS 菜单栏；Swift 6.2、SwiftUI、Tuist | 多种 AI Coding 套餐 | `QuotaMonitor` 单一状态源、Repository 协议、依赖注入、provider 测试流程、自动签名发布 | MIT；macOS 15+ |
| [ccusage](https://github.com/ccusage/ccusage) | 跨平台 CLI | 读取 Claude Code、Codex、Gemini CLI、Copilot CLI 等本地日志 | 多种日志格式解析、按日/周/月/会话聚合、缓存 Token 计价、离线价格表 | 本地统计是估算，不能代替服务商账单 |
| [TokenBudget](https://tokenbudget.com/) | 自托管代理/SDK + Dashboard | API Token、费用、延迟与项目归因 | 通过代理观察每次请求，适合团队或服务端统计 | 更重，不是菜单栏竞品，但可参考成本归因 |
| [LiteLLM](https://github.com/BerriAI/litellm) | LLM Gateway | 多模型路由、虚拟 Key、预算与支出日志 | 中转站适配、按 key/user/team 统计、统一网关数据源 | 更适合作为 MiracleDeck 的数据源，而非 UI 竞品 |
| [One API](https://github.com/songquanpeng/one-api) / [New API](https://github.com/QuantumNous/new-api) | 自托管中转站 | 国内常见 OpenAI 兼容中转、用户额度和消费日志 | 定义 New API/One API 专用 adapter，覆盖大量第三方站点 | New API 不是简单的标准 MIT 项目，引用代码前应单独核对其最新双许可条款 |

### 2.1 对竞品的判断

- **不应简单复制 CodexBar**：它已经非常全面。新项目若只做“另一个 Codex/Claude 菜单栏”，价值较弱。
- **可以合法参考 MIT 项目**：若直接复制代码，必须保留原许可与版权声明；如果大量继承，最好明确说明来源。
- **值得做的重点**：第三方中转站、多个账户并排、人民币/美元统一展示、余额预警、国内网络环境、可扩展的自定义 HTTP adapter。
- **建议兼容而非对抗**：未来可导入 CodexBar/OpenUsage 的本地配置，或提供 localhost JSON 输出，让其他状态栏/桌面组件复用数据。

### 2.2 Fork 还是独立实现

| 方案 | 优点 | 代价 | 适用情况 |
| --- | --- | --- | --- |
| Fork CodexBar | 最快获得大量 provider、套餐和发布能力 | 上游体量很大，长期同步困难；产品定位和 UI 很难真正独立 | 目标是快速做一个内部版或少量定制版 |
| 给 CodexBar/OpenUsage 贡献 | 复用成熟用户群和维护体系 | 路线、合并节奏和品牌不由自己控制 | 只想补 DeepSeek/New API 等少数能力 |
| 独立实现，小范围借鉴 | 架构和产品边界最清楚，适合国内中转与小卡片定位 | 初期需要自己完成凭据、缓存、发布与 provider 测试 | 准备长期维护一个有独立定位的开源项目 |

本项目推荐第三种：独立实现一个更小的核心，阅读 CodexBar/OpenUsage 的协议和边界处理，只有在确实能降低风险时才复制少量 MIT 代码，并在对应文件与 `NOTICE` 中保留来源。不要首版照搬几十个 provider；把 New API/One API、多账户、人民币显示和自定义只读 HTTP adapter 做成明显优势。

## 3. 各类数据的可获得性

### 3.1 可行性总表

| 数据源 | 可显示内容 | 推荐获取方式 | 稳定性 | 主要限制 |
| --- | --- | --- | --- | --- |
| OpenAI 官方 API | 组织花费、Token、请求数、按模型/项目聚合 | 官方 Organization Usage/Costs API | 高 | 需要 Organization Admin Key；普通项目 Key 不够；没有统一公开的“预付余额”新接口 |
| DeepSeek 官方 API | 当前可用余额、赠送/充值余额、币种 | 官方 `GET /user/balance` | 高 | 官方文档未提供同等粒度的历史用量 API；消耗可由余额差值或本地请求日志补充，但只是估算 |
| Anthropic 官方 API | 组织用量、Token、费用、模型/工作区维度 | 官方 Usage & Cost Admin API | 高 | 需要组织 Admin API Key；个人账户不可用；不是 Claude Pro/Max 套餐额度 |
| OpenRouter | 购买 credits、累计 usage、剩余值 | 官方 `GET /api/v1/credits` | 高 | 需要 management key；应让用户明确选择权限更高的 key |
| New API / One API 中转 | 用户 quota、used_quota、请求数、分时日志统计 | 管理 API `/api/user/self`、`/api/log/self/stat` | 中 | 通常需要“控制台 Access Token + 用户 ID”，不能假定模型调用 `sk-` Key 可访问；不同站点可能改接口或单位 |
| LiteLLM Proxy | key/user/team spend、budget、日志 | LiteLLM 管理/支出接口 | 中高 | 管理 API 版本变化，权限差异大；需要适配服务端版本 |
| Codex/ChatGPT 套餐 | 5 小时/周窗口、重置时间、credits | Codex OAuth/CLI RPC；本地 CLI 数据 | 中 | 不是 OpenAI API 账单；部分端点属于产品内部接口而非稳定公共开发者 API |
| Claude Pro/Max/Team 套餐 | 5 小时、周额度、模型周额度、刷新时间、extra usage | Claude OAuth usage、Claude CLI `/usage`，网页接口作为回退 | 中或低 | 官方没有面向第三方桌面应用的稳定套餐 usage API；OAuth/网页路径可能变化或触发权限问题 |
| Claude Code/Codex 本地使用 | Token、模型、时间、估算成本 | 只读解析本地 JSONL | 中高 | 只包含本机日志；工具调用和服务端最终账单可能不一致 |

### 3.2 OpenAI 官方 API

OpenAI 公开了组织级 Usage 与 Costs API。例如：

```http
GET https://api.openai.com/v1/organization/costs?start_time=...&bucket_width=1d
Authorization: Bearer $OPENAI_ADMIN_KEY
```

以及 completions usage：

```http
GET https://api.openai.com/v1/organization/usage/completions?start_time=...&bucket_width=1d
Authorization: Bearer $OPENAI_ADMIN_KEY
```

实现注意点：

- 使用 Unix 秒时间范围和分页游标；
- 日粒度数据适合 Today / 7d / 30d 卡片；
- 可按 `project_id`、`model`、`line_item` 聚合；
- Admin Key 必须存入 macOS Keychain；
- 普通 API Key 或 project service account key 可能无法访问组织级接口；
- `/v1/dashboard/billing/credit_grants` 是旧的、未进入当前公开 API Reference 的接口，只能做可关闭的 best-effort fallback，不能作为核心承诺。

官方参考：[OpenAI Usage API Reference](https://platform.openai.com/docs/api-reference/usage)；[OpenAI Token Usage 帮助](https://help.openai.com/en/articles/6614209-how-do-i-check-my-token-usage)。

### 3.3 DeepSeek 官方 API

DeepSeek 有非常适合菜单栏卡片的官方余额接口：

```http
GET https://api.deepseek.com/user/balance
Authorization: Bearer $DEEPSEEK_API_KEY
Accept: application/json
```

响应包含：

- `is_available`：余额是否足够继续调用；
- `balance_infos[].currency`：`CNY` 或 `USD`；
- `total_balance`；
- `granted_balance`；
- `topped_up_balance`。

官方参考：[DeepSeek Get User Balance](https://api-docs.deepseek.com/api/get-user-balance/)。

当前应把 DeepSeek 定位为“余额卡片”。如果用户想看日/月 Token 消耗，优先选择：

1. 记录应用自身发起请求的 response usage；
2. 读取兼容客户端/网关的本地日志；
3. 定时采样余额并显示余额变化趋势。

第 3 种不能准确等价为 Token：赠送、充值、价格变化和缓存计价都会影响结果，UI 必须写“余额变化”而非“Token 用量”。

### 3.4 Anthropic 官方 API

Anthropic 提供组织级 Usage & Cost Admin API：

```http
GET https://api.anthropic.com/v1/organizations/usage_report/messages
x-api-key: $ANTHROPIC_ADMIN_KEY
anthropic-version: 2023-06-01
```

```http
GET https://api.anthropic.com/v1/organizations/cost_report
x-api-key: $ANTHROPIC_ADMIN_KEY
anthropic-version: 2023-06-01
```

它能按时间桶、模型、workspace、API key、service tier 等过滤或分组，也能区分普通 input、cache read、cache creation 和 output tokens。

重要边界：

- 这是 Claude Platform API 组织账单，不是 Claude Pro/Max 套餐额度；
- 需要 `sk-ant-admin...` Admin Key；
- 官方明确说明个人账户不能使用该 Admin API；
- 费用单位和字符串精度必须按官方 schema 解析，不要用浮点数直接累加金额。

官方参考：[Anthropic Usage and Cost API](https://platform.claude.com/docs/en/manage-claude/usage-cost-api)。

### 3.5 OpenRouter

OpenRouter 的官方 credits endpoint：

```http
GET https://openrouter.ai/api/v1/credits
Authorization: Bearer $OPENROUTER_MANAGEMENT_KEY
```

核心字段是 `total_credits` 与 `total_usage`，余额可计算为二者之差。参考：[OpenRouter Get remaining credits](https://openrouter.ai/docs/api/api-reference/credits/get-credits)。

### 3.6 New API / One API 及同类第三方中转

国内大量中转站基于 New API 或 One API 二次开发。最有价值的两个接口是：

```http
GET {baseURL}/api/user/self
Authorization: Bearer {console_access_token}
New-Api-User: {user_id}
```

典型响应包含 `quota`、`used_quota`、`request_count`、用户分组等。参考：[New API 用户模块](https://doc.newapi.pro/api/fei-user/)。

```http
GET {baseURL}/api/log/self/stat?type=2&start_timestamp=...&end_timestamp=...
Authorization: Bearer {console_access_token}
New-Api-User: {user_id}
```

典型响应包含时间范围内消耗 quota、RPM、TPM。参考：[New API 日志模块](https://doc.newapi.pro/api/fei-log/)。

适配时必须注意：

- 模型调用 Key 与控制台 Access Token 是两种凭据；默认只申请只读控制台 Token；
- 有些站点只支持 Cookie session，最好后置支持，不要首版自动读取浏览器 Cookie；
- `quota` 的金额换算可能受站点配置影响，不应写死 `quota / 500000`；adapter 应先读取站点公开配置，读取不到时显示原始额度或让用户配置换算率；
- 同一个 New API fork 可能改 header、字段或分页，必须保存脱敏 fixture 做回归测试；
- `/v1/models` 只能说明模型调用 Key 可用，不能证明管理接口或余额接口可用。

建议实现两个层次：

1. `NewAPIProvider`：对标准 New API/One API 响应有强类型解析；
2. `CustomHTTPProvider`：高级用户可配置 URL、method、header、JSONPath 字段映射、币种和单位。

自定义 provider 首版只允许 GET；禁止请求体脚本、任意 JavaScript 和 shell 命令，降低密钥泄露和供应链风险。

## 4. GPT/Claude 官方套餐 usage 的现实边界

### 4.1 Codex / ChatGPT 套餐

OpenAI 的 API 计费与 ChatGPT 订阅是两套独立系统，不能把 API credits 当作 ChatGPT Plus/Pro 额度。官方也明确说明两者分开计费：[OpenAI 帮助说明](https://help.openai.com/en/articles/8156019-is-api-usage-included-in-chatgpt-subscriptions-even-if-i-have-a-paid-chatgpt-account)。

可行实现按优先级排序：

1. 读取 `~/.codex/auth.json` 中现有 OAuth 凭据；
2. 通过 `codex app-server` JSON-RPC 调用 `account/read` 与 `account/rateLimits/read`；
3. 解析 Codex 本地 session JSONL 得到 Token/成本；
4. 用户显式开启后，使用网页会话补充 dashboard-only 字段。

CodexBar 已验证的结构包括 primary/secondary rate window、reset timestamp、credits 和 account plan。其实现说明见 [Codex provider 文档](https://github.com/steipete/CodexBar/blob/main/docs/codex.md)。

风险提示：套餐 usage 相关的 `chatgpt.com/backend-api/...` 并非面向普通第三方应用承诺兼容性的公开 OpenAI Platform API。应把它标为“实验性数据源”，失败时退回 CLI RPC 或本地日志，并避免高频请求。

### 4.2 Claude Pro / Max / Team 套餐

可行实现按优先级排序：

1. 复用 Claude Code 已有 OAuth 凭据，调用 usage endpoint；
2. 启动隔离、只读的 Claude CLI PTY，执行 `/usage` 并解析结果；
3. 用户显式授权后使用 claude.ai session cookie 与网页 usage 接口；
4. 本地解析 `~/.claude/projects/**/*.jsonl`，显示 Token 与估算成本，但不能把它冒充服务端额度百分比。

可借鉴的具体数据包括 5 小时窗口、7 天窗口、Sonnet/Opus 专属周窗口、extra usage 和 reset time。CodexBar 的详细策略见 [Claude provider 文档](https://github.com/steipete/CodexBar/blob/main/docs/claude.md)。

风险提示：Claude 套餐的 OAuth/网页 usage 接口不是一个面向所有第三方客户端、长期稳定的公共 API。必须：

- 低频轮询；
- 只复用用户已经登录的凭据，不收集密码；
- 不将 cookie/OAuth token 发到项目自己的服务器；
- 提供一键断开和删除凭据；
- 解析失败时显示“数据源不可用”，不要根据本地 Token 猜额度百分比。

## 5. 推荐技术方案

### 5.1 UI 技术选型

推荐：**Swift 6 + SwiftUI，必要处使用 AppKit**。

理由：

- `MenuBarExtra` 可以直接构建只存在于菜单栏的 utility app，并用 `.menuBarExtraStyle(.window)` 展示复杂小窗；Apple 官方文档见 [MenuBarExtra](https://developer.apple.com/documentation/swiftui/menubarextra)；
- `LSUIElement = true` 可隐藏 Dock 与应用切换器图标；
- 若要做全局快捷键、可聚焦输入、精确控制窗口位置、失焦关闭和状态栏文字 pin，使用 `NSStatusItem + NSPanel` 更灵活；`NSStatusItem` 官方文档见 [Apple Developer](https://developer.apple.com/documentation/appkit/nsstatusitem)；
- 无需捆绑 Chromium/Node runtime，内存、启动速度、包体和系统一致性更容易控制。

首版建议直接采用 `NSStatusItem + NSPanel`，SwiftUI 作为 panel 内容。纯 `MenuBarExtra` 可以做原型，但复杂交互后通常仍会下沉 AppKit。

### 5.2 核心数据模型

不要为每个 provider 定义一套 UI。所有数据源归一化为同一份 snapshot：

```swift
struct ProviderSnapshot: Sendable, Codable {
    let providerID: String
    let accountID: String?
    let displayName: String
    let planName: String?
    let balance: MoneyAmount?
    let spend: [SpendPeriod]
    let tokenUsage: [TokenPeriod]
    let quotaWindows: [QuotaWindow]
    let fetchedAt: Date
    let source: DataSourceKind
    let freshness: Freshness
    let diagnostics: [Diagnostic]
}

struct QuotaWindow: Sendable, Codable {
    let id: String
    let title: String
    let usedRatio: Decimal?
    let used: Decimal?
    let limit: Decimal?
    let resetsAt: Date?
}
```

金额使用 `Decimal`，不要使用 `Double`。Token 使用 `Int64`。所有时间保存为 UTC `Date`，只在 UI 层转成本地时区。

provider 最小协议可以是：

```swift
protocol UsageProvider: Sendable {
    var metadata: ProviderMetadata { get }
    func validate(configuration: ProviderConfiguration) async throws
    func fetch(context: FetchContext) async throws -> ProviderSnapshot
}
```

把认证、HTTP client、解析和映射拆开，便于 fixture 测试：

```text
CredentialStore -> ProviderClient -> ProviderParser -> SnapshotMapper
                                             |
                                             v
                                      ProviderSnapshot
```

### 5.3 模块建议

```text
MiracleDeckApp/
  App/                 # NSStatusItem、NSPanel、设置窗口、通知
  Domain/              # Snapshot、Money、QuotaWindow、错误类型
  ProviderKit/         # provider 协议、注册表、调度、公共 HTTP
  Providers/
    OpenAIAPI/
    DeepSeek/
    AnthropicAPI/
    OpenRouter/
    NewAPI/
    CodexPlan/
    ClaudePlan/
    CustomHTTP/
  LocalUsage/          # Claude/Codex JSONL scanner、价格表、缓存
  Persistence/         # Keychain、UserDefaults/JSON、历史采样
  UI/                  # 卡片、进度条、错误、设置页
  Tests/Fixtures/      # 脱敏响应和日志样本
```

### 5.4 刷新与缓存

推荐 stale-while-revalidate：

- 启动立即显示上次成功快照；
- 后台刷新，不让菜单弹出等待网络；
- 官方余额/套餐接口默认 5 分钟；
- 组织 usage/cost 默认 15 分钟；
- 本地日志在文件变更后 debounce 2–5 秒，或打开面板时增量扫描；
- 失败使用指数退避，网络恢复或用户手动刷新时立即重试；
- 同一 provider/account 永远只允许一个 in-flight request；
- 加少量随机 jitter，避免所有用户整点同时请求服务商；
- 数据卡显示“刚刚/5 分钟前”，超过阈值标记 stale；
- 只缓存归一化结果和非敏感诊断，不把 token/cookie 写进日志或普通 JSON。

可以用 Swift `actor RefreshCoordinator` 管理状态，并用 `URLSession` 的 ephemeral configuration 发请求，避免不必要的 cookie 持久化。

### 5.5 凭据安全

- API Key、Admin Key、Access Token、Cookie 必须存 Keychain；Apple 说明 Keychain 用于加密保存小型秘密：[Keychain Services](https://developer.apple.com/documentation/security/keychain-services)。
- 普通设置（provider 顺序、颜色、刷新间隔、base URL）才写 UserDefaults 或配置文件。
- Keychain item 用 `service = bundleID.providerID`、`account = accountID` 区分多账户。
- 日志统一经过 redactor，至少屏蔽 Bearer、`sk-...`、Cookie、JWT、query token。
- “复制诊断信息”必须先生成脱敏预览供用户确认。
- 不运行用户输入的 shell，不自动扫描全部浏览器 cookie；需要 cookie 的实验功能必须单独解释权限。
- 自定义 base URL 默认要求 HTTPS；localhost 可例外；不提供“忽略 TLS 错误”开关。

### 5.6 启动、更新和发布

- 登录时启动使用 `SMAppService.mainApp.register()`；参考 [Apple Service Management](https://developer.apple.com/documentation/servicemanagement)；
- 开源分发可先用 GitHub Releases + Homebrew Cask；
- 面向普通用户必须 Developer ID 签名与 notarization，否则 Gatekeeper 体验很差；
- 自动更新可采用 [Sparkle](https://sparkle-project.org/)，并对 appcast 和安装包签名；
- CI 至少构建 universal binary、跑单元测试、校验无调试 entitlement、生成 SBOM/校验和；
- 第一版最低系统建议 macOS 14，能兼顾现代 SwiftUI 与更多用户。若使用 macOS 15 专属 API，应有明确收益再提高门槛。

## 6. UI 信息架构

窗口建议控制在约 320–380 pt 宽，默认只展示最重要的数字：

```text
┌──────────────────────────────────┐
│ MiracleDeck          ↻   ⚙︎   │
├──────────────────────────────────┤
│ DeepSeek API                    │
│ ¥ 83.42 可用     今日 -¥ 2.18   │
│ 赠送 ¥3.42 · 充值 ¥80.00        │
├──────────────────────────────────┤
│ Codex Plus                      │
│ 5 小时   ███████░░░  72%        │
│                    2h 14m 后刷新 │
│ 每周     ████░░░░░░  41%        │
│                    周一 08:00    │
├──────────────────────────────────┤
│ My New API                      │
│ $12.60 可用 · 30 天消费 $18.24  │
└──────────────────────────────────┘
```

交互原则：

- provider 卡片可折叠，拖动排序；
- 状态栏可 pin 一个关键值，如 `DS ¥83` 或 `CX 72%`；
- “已用”和“剩余”可全局切换，但同一屏不要混用；
- reset 同时显示相对时间和绝对时间，避免跨时区误解；
- 绿色/黄色/红色不能作为唯一信息，还应有百分比和文字；
- 数据源类型应可查看：官方 API / 本地日志 / OAuth / 实验性网页；
- 错误应区分认证失效、权限不足、接口变化、网络失败和被限流。

## 7. MVP 范围建议

### v0.1：建立正确骨架

- macOS 菜单栏 + 小卡片窗口；
- 多 provider 注册、启停、排序；
- Keychain 凭据；
- stale-while-revalidate 缓存；
- OpenAI Organization Usage/Costs；
- DeepSeek balance；
- OpenRouter credits；
- New API/One API balance + period stat；
- Codex CLI/OAuth rate windows；
- Claude OAuth/CLI rate windows；
- 统一错误、脱敏诊断、手动刷新；
- fixture 单元测试和 GitHub Actions。

### v0.2：本地成本与历史

- Claude Code/Codex JSONL 增量扫描；
- Today / Yesterday / 7d / 30d Token 与估算成本；
- 模型价格表在线更新 + 内置离线 fallback；
- 余额历史、消费速率和预计耗尽日；
- 低余额/临近额度通知。

### v0.3：开放生态

- `CustomHTTPProvider`；
- provider manifest + JSON fixture 验证工具；
- localhost 只读 JSON API；
- CLI 输出；
- 配置导入/导出（默认不导出秘密）；
- 社区 provider 模板与贡献指南。

暂缓：

- 首版 Windows/Linux；
- 云端账号同步；
- 自动抓取所有浏览器 Cookie；
- 在应用内代理所有 LLM 请求；
- 团队级复杂 observability；
- 直接执行第三方 provider 脚本。

## 8. 测试策略

这类软件最大的维护成本不是 UI，而是上游响应格式变化。每个 provider 至少需要：

- 正常响应 fixture；
- 字段缺失/新增 fixture；
- 401、403、404、429、5xx；
- 空用量、多币种、小数精度、超大 Token；
- reset time 为 ISO8601、Unix 秒、Unix 毫秒或相对文本；
- 响应中出现 secret 时的日志脱敏测试；
- 多账户隔离与缓存 key 测试；
- 上一次成功数据 + 本次失败时的 stale 状态测试。

不要在 CI 中依赖真实用户 API Key。可增加手动 opt-in 的 live contract tests，但默认只跑脱敏 fixture。

## 9. 开源项目维护建议

仓库早期应补齐：

- `LICENSE`：若无特殊商业计划，MIT 与同类生态最兼容；
- `SECURITY.md`：明确密钥泄露、provider SSRF、日志脱敏等问题的私下报告方式；
- `CONTRIBUTING.md`：新增 provider 的固定步骤与 fixture 要求；
- `CODE_OF_CONDUCT.md`；
- provider 支持矩阵：数据来源、权限、稳定等级、最近验证日期；
- 隐私说明：哪些请求直连服务商、哪些数据只保存在本地；
- 发布流程：签名、notarization、Sparkle、公钥与 checksum；
- 商标与命名检查，避免名称过度接近 CodexBar/OpenUsage/ClaudeBar。

建议给 provider 标注稳定等级：

- `Stable`：官方公开 API；
- `Compatible`：第三方项目公开管理 API；
- `Local`：只读本地日志或 CLI；
- `Experimental`：OAuth 产品接口、网页 Cookie、DOM scraping。

每次上游接口变化都更新 `lastVerifiedAt`，这会比笼统写“支持某某服务”更诚实，也更方便社区维护。

## 10. 建议的下一步

1. 确定项目定位：重点突出“官方 API + 国内中转 + 套餐额度”三合一；
2. 定义 `ProviderSnapshot`、`UsageProvider`、错误模型和凭据模型；
3. 用 DeepSeek + New API 做第一组 adapter，验证余额和单位抽象；
4. 用 Codex 做第一组 quota window，验证 reset time 与 OAuth/CLI fallback；
5. 做 320–380 pt 的状态栏 panel 原型；
6. 写 fixture 测试后再扩 OpenAI、Anthropic、Claude；
7. 第一版发布前完成签名、notarization、隐私文档和 SECURITY.md。

最重要的产品约束是：**只有服务端返回的额度才显示为“额度”；本地 Token 和价格换算必须显示为“估算”。** 这样可以避免用户把近似值误认为真实账单或真实套餐剩余量。

## 11. 主要资料索引

### 开源实现

- [CodexBar README](https://github.com/steipete/CodexBar)
- [CodexBar OpenAI provider](https://github.com/steipete/CodexBar/blob/main/docs/openai.md)
- [CodexBar Codex provider](https://github.com/steipete/CodexBar/blob/main/docs/codex.md)
- [CodexBar Claude provider](https://github.com/steipete/CodexBar/blob/main/docs/claude.md)
- [OpenUsage](https://github.com/robinebers/openusage)
- [ClaudeBar](https://github.com/tddworks/ClaudeBar)
- [ccusage](https://github.com/ccusage/ccusage)
- [One API](https://github.com/songquanpeng/one-api)
- [New API](https://github.com/QuantumNous/new-api)
- [LiteLLM](https://github.com/BerriAI/litellm)

### 官方/项目 API 文档

- [OpenAI Usage API](https://platform.openai.com/docs/api-reference/usage)
- [DeepSeek Get User Balance](https://api-docs.deepseek.com/api/get-user-balance/)
- [Anthropic Usage and Cost API](https://platform.claude.com/docs/en/manage-claude/usage-cost-api)
- [OpenRouter Credits API](https://openrouter.ai/docs/api/api-reference/credits/get-credits)
- [New API 用户模块](https://doc.newapi.pro/api/fei-user/)
- [New API 日志模块](https://doc.newapi.pro/api/fei-log/)
- [LiteLLM Spend Tracking](https://docs.litellm.ai/docs/proxy/cost_tracking)

### macOS 实现

- [Apple MenuBarExtra](https://developer.apple.com/documentation/swiftui/menubarextra)
- [Apple NSStatusItem](https://developer.apple.com/documentation/appkit/nsstatusitem)
- [Apple Keychain Services](https://developer.apple.com/documentation/security/keychain-services)
- [Apple Service Management](https://developer.apple.com/documentation/servicemanagement)
- [Sparkle](https://sparkle-project.org/)
