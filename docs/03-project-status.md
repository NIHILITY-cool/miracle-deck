# 项目进度

> 更新日期：2026-07-17

## 当前阶段

项目处于 `0.0.1` 工程验证阶段。M0 基础工程大部分完成，M1 菜单栏外壳已有可运行原型，但尚未接入真实 Provider。

## 已完成

- 安装并启用 Xcode 26.6；
- 默认开发工具链已切换至完整 Xcode；
- Swift 6.3.3 编译环境验证通过；
- 初始化本地 Git 仓库，默认分支为 `main`；
- 创建 XcodeGen 可复现工程配置；
- 创建原生 macOS 菜单栏 App；
- 实现 `NSStatusItem + NSPanel` 基础交互；
- 设置最低系统版本为 macOS 14；
- 开启 Swift 6 strict concurrency；
- 创建 `TokenMonitorCore`、`TokenMonitorProviders`、`TokenMonitorUI`；
- 定义首批领域模型；
- 加入 DeepSeek、Codex、New API Mock 数据；
- 实现首版 Hero 卡与多平台列表切换；
- 添加 MIT License、隐私、安全和贡献文档；
- 添加 GitHub Actions 构建与测试工作流；
- 本地 Debug App 构建成功；
- 4 个基础测试通过；
- 构建出的 Debug App 当前约 836 KB。

## 尚未完成

- 最终产品名称和 Bundle Identifier；
- 远程 GitHub 仓库与分支保护；
- CI 在远程 GitHub Runner 上的首次验证；
- SwiftFormat 或 SwiftLint；
- 正式图标和 Design Token；
- Panel 多显示器、点击外部关闭和键盘交互验收；
- Keychain、账户仓库、缓存和刷新协调器；
- DeepSeek、New API、Codex 真实数据接入；
- 签名、公证、Sparkle 和 Homebrew Cask。

## 当前命名状态

代码和工程暂用：

```text
Product: Token Monitor
Executable: TokenMonitor
Bundle ID: app.tokenmonitor.desktop
```

这些都是工程代号，可以在首次公开发布前统一替换。候选品牌名优先考虑 `MiracleDeck`，仓库名建议使用 `miracle-deck`。

## 下一里程碑

M1 菜单栏外壳：

1. 冻结产品名称与第一版视觉 Token；
2. 完善 Panel 定位和关闭行为；
3. 加入分类过滤和稳定的账户选择状态；
4. 完成浅色、深色和高对比模式；
5. 补齐 Mock Provider 的 loading、stale、error 等状态；
6. 加入视觉和交互验收。
