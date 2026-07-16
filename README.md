# MiracleDeck

一个计划中的轻量级 macOS 菜单栏应用，用来集中查看：

- OpenAI、DeepSeek、Anthropic 等官方 API 的余额、Token 用量和费用；
- New API、One API、LiteLLM 等第三方中转服务的余额和消耗；
- Codex、Claude 等订阅套餐的使用窗口、剩余额度与刷新时间；
- 本地 Claude Code、Codex 等 CLI 日志中的 Token 与估算成本。

项目目前处于 `0.0.x` 工程验证阶段。首个代码骨架包含原生
`NSStatusItem + NSPanel` 菜单栏外壳、Mock Provider、三个本地 Swift
Package 和基础 CI；尚未连接真实账户。

## 本地开发

要求：

- macOS 14 或更高版本；
- Xcode 16 或更高版本；
- XcodeGen。

```bash
brew install xcodegen
make verify
open MiracleDeck.xcodeproj
```

如果系统尚未把完整 Xcode 设为默认工具链，可以先运行：

```bash
sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
```

项目运行时不依赖 Conda、Python、Electron 或项目自建云服务。

## 文档

- [同类项目与实现方案调研](docs/01-landscape-and-implementation-research.md)
- [Quota Float 设计拆解](design.md)
- [项目实施计划与注意事项](docs/02-implementation-plan.md)
- [当前项目进度](docs/03-project-status.md)
- [版本变更记录](CHANGELOG.md)

## 隐私与安全

- [隐私边界](PRIVACY.md)
- [安全策略](SECURITY.md)
- [贡献指南](CONTRIBUTING.md)
