# MiracleDeck 设计拆解：Quota Float

> 参考项目：[change-42-yhmm/quota-float](https://github.com/change-42-yhmm/quota-float)
> 分析日期：2026-07-16
> 目的：提取可迁移到 MiracleDeck 的视觉语言、信息架构和交互原则，不直接复制成品。

![Quota Float 的三种额度状态](https://raw.githubusercontent.com/change-42-yhmm/quota-float/main/docs/images/quota-states.png)

## 1. 设计结论

Quota Float 的审美可以概括为：

> 柔和环境光、超大数字、低干扰控制，以及能退化成一个小型状态物件的桌面工具。

它并不是传统仪表盘，也不是常见的深色开发者工具。它更像一个放在桌面上的数字化小物件：

- 使用系统字体，不强调复杂品牌字体；
- 使用大圆角、淡边框和柔和环境色，建立亲和感；
- 核心数字占据视觉中心，用户无需阅读完整卡片；
- 健康、注意、危险状态通过整体色温变化表达；
- 闲置时缩成一个 80×80 的浮动状态块；
- 控制按钮被弱化，只有需要操作时才进入视野；
- 对错误、过期和未登录状态使用独立界面，不伪造数据。

它最成功的地方不是某个单独的颜色或动画，而是所有视觉元素都服从同一个目标：

> 让用户在一秒内知道额度是否安全，同时让这个常驻窗口看起来不像一个监控面板。

### 设计参数判断

| 参数 | 判断 | 说明 |
| --- | --- | --- |
| 设计变化度 | 4/10 | 布局稳定、对称、易理解，主要变化来自动态背景 |
| 动效强度 | 3/10 | 动画很慢，主要营造环境感，不承担复杂叙事 |
| 信息密度 | 6/10 | 320×320 内放入两个额度周期、重置时间、状态和控制 |
| 情绪关键词 | 柔和、安静、漂浮、亲和、可靠 | 没有典型开发者工具的硬边框和高对比 |
| 设计家族 | Soft Aurora Utility | 柔光环境色与系统级工具界面的结合 |

## 2. 产品形态

Quota Float 实际上有三层产品形态：

1. 系统托盘入口；
2. 100×100 的常驻浮动窗口；
3. hover 后展开为 320×320 的完整卡片。

窗口由 Tauri 创建，使用透明、无系统边框、置顶和跳过任务栏的配置。网页内容使用 React 和 CSS 绘制。

关键尺寸如下：

| 元素 | 尺寸 |
| --- | --- |
| 收起窗口 | 100×100 |
| 浮动 Orb | 80×80，四周各保留 10px |
| 展开窗口 | 320×320 |
| 主卡片圆角 | 38px |
| Orb 圆角 | 28px |
| 卡片水平内边距 | 30px |
| 顶部控制按钮 | 25×25 |
| 主数字 | 64px |
| 周额度数字 | 30px |
| 主进度条 | 6px |

源码参考：

- [Tauri 窗口配置](https://github.com/change-42-yhmm/quota-float/blob/main/src-tauri/tauri.conf.json)
- [展开与收起逻辑](https://github.com/change-42-yhmm/quota-float/blob/main/src/lib/bridge.ts)
- [主界面状态管理](https://github.com/change-42-yhmm/quota-float/blob/main/src/App.tsx)

## 3. 信息架构

完整卡片被分为四个稳定区域：

```text
┌──────────────────────────────────┐
│ Provider / Plan       状态与控制 │
│ 当前额度周期说明                 │
│                                  │
│ 74%                              │
│ ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━    │
│ 1h 18m 后重置                    │
│                                  │
│ 周额度说明                       │
│ 42%                        Logo  │
│ 重置机会 / 补充信息              │
└──────────────────────────────────┘
```

### 3.1 顶部：身份和控制

左侧是服务商与套餐，右侧是状态和三个小型控制。

身份使用大写、小字号和较宽字距：

```text
CODEX · PRO
5-hour remaining
```

这部分不抢主数字，却能快速回答两个问题：

- 当前看的是哪个服务；
- 当前账户属于什么套餐。

右侧控制均放入半透明圆形容器中：

- 额度是否正在消耗；
- 切换语言；
- 切换置顶；
- 多 provider 时切换上下一个服务。

设计上的重要处理是：控制按钮只有 25px，视觉重量远低于数字。它们存在，但不会把卡片变成工具栏。

### 3.2 中部：唯一主指标

5 小时额度是卡片唯一的视觉主角：

- 64px 主数字；
- 21px 百分号；
- `font-weight: 500`，没有使用厚重黑体；
- 负字距使两位数字更紧凑；
- `line-height: 0.82` 压缩数字占用的垂直高度。

数字、进度条和重置时间构成一个连续阅读单元：

```text
74%
██████████████░░░░░
resets in 1h 18m
```

视觉顺序非常清楚：

1. 还剩多少；
2. 大约处于什么位置；
3. 什么时候恢复。

### 3.3 底部：次要周期

周额度被放在左下角，字号明显降级：

- 标签 12px；
- 数字 30px；
- 重置机会 12px；
- 详情使用文字链接，不增加新的按钮容器。

这避免两个额度周期争夺注意力。用户首先看到短周期，再决定是否读取周额度。

### 3.4 右下：视觉落点

Codex 标志放在右下角，尺寸约 43px。

它有三个作用：

- 填补右下区域，使卡片视觉平衡；
- 提供服务商识别；
- 给未来多 provider 切换留下稳定的品牌位置。

它没有出现在顶部标题左侧，因此不会挤压文字，也不会让顶部变得像列表项。

## 4. 视觉层级

Quota Float 使用的层级不是依靠大量卡片和分割线，而是依靠字号、位置和透明度。

| 层级 | 内容 | 典型字号 | 视觉处理 |
| --- | --- | --- | --- |
| L1 | 5 小时剩余百分比 | 64px | 最大、最深、负字距 |
| L2 | 周额度百分比 | 30px | 放在固定底部区域 |
| L3 | Provider、Plan、周期标题 | 14px | 大写、宽字距 |
| L4 | 重置时间、解释文字 | 12px | 降低透明度 |
| L5 | 控制按钮和补充入口 | 10-13px | 半透明、低对比 |

它没有使用粗重标题、彩色标签或多层卡片边框。卡片内绝大部分结构由空白完成。

### 可以迁移的原则

- 一个卡片只能有一个最大数字；
- 次要额度必须降级，不能与主额度同尺寸；
- 进度条只服务主指标；
- 状态控制靠边放置；
- 品牌标志用于构图，不用于抢占标题；
- 辅助信息用低对比文本，不要全部装进 Badge。

## 5. 形状系统

Quota Float 的形状语言高度统一：

- 主容器为大圆角矩形；
- 小控制全部为圆形或胶囊；
- 进度条为完整胶囊；
- tooltip 使用较小圆角；
- 错误图标使用圆形容器。

它看起来接近 squircle，但实现上仍是普通 CSS `border-radius`。

### 当前形状规则

| 组件 | 圆角 |
| --- | --- |
| 320px 主卡片 | 38px |
| 80px Orb | 28px |
| 圆形控制 | 50% |
| 语言按钮 | 999px |
| 进度条 | 999px |
| Tooltip | 10px |
| 错误刷新按钮 | 999px |

主卡片圆角约为宽度的 11.9%，Orb 圆角约为宽度的 35%。收起后的形状更柔软，像一个独立状态物件；展开后圆角相对克制，以免大卡片过度卡通化。

### 对 MiracleDeck 的建议

保持三层形状系统：

```text
大容器：28-36px
普通卡片：16-20px
按钮与状态：圆形或完整胶囊
```

不要同时出现 6px、10px、14px、22px、38px 等大量没有规则的圆角。

## 6. 色彩系统

### 6.1 基础表面

主卡片底色为非常浅的冷灰蓝：

```text
#EDF3F8
```

边框与高光采用透明白色：

```text
border: rgba(255,255,255,0.34)
inner highlight: rgba(255,255,255,0.42)
```

阴影极轻：

```text
0 1px 8px rgba(90,108,132,0.05)
```

这意味着卡片的立体感主要来自内部光线，而不是外部投影。它不会像一个网页 Card，更像桌面上的半透明物件。

### 6.2 Aurora 环境色

背景不是单个线性渐变，而是四层颜色叠加：

1. 左下的柔和 glow；
2. 右下的暖色；
3. 顶部的冷色；
4. 最底层的线性渐变。

整个渐变层被放大并超出容器：

```text
inset: -35%
scale: 1.1
opacity: 0.42-0.56
```

这样做的结果是用户看不到明显的渐变中心和边缘，只能感受到缓慢变化的环境色。

### 6.3 语义状态

项目没有简单地把整个背景换成绿色、黄色或红色，而是改变背景色温和进度条颜色。

| 状态 | 条件 | 背景倾向 | 进度条 |
| --- | --- | --- | --- |
| Healthy | 剩余 ≥ 50% | 冷蓝、薄荷 | 蓝色 |
| Caution | 10% ≤ 剩余 < 50% | 淡黄、冷灰蓝 | 蓝色 |
| Critical | 剩余 < 10% | 桃橙、淡红 | 橙色 |
| Stale | 数据过期 | 灰色状态提示 | 灰色 |
| Unavailable | 数据不可用 | 保留容器，显示错误状态 | 橙色提示 |
| Signed out | 未登录 | 蓝紫与粉灰 | 登录提示 |

这种做法比“安全绿卡、警告黄卡、危险红卡”更克制。状态改变是能感知的，但不会让桌面长期出现刺眼色块。

### 对 MiracleDeck 的重要限制

不同数据类型不能共享同一套阈值：

- 套餐额度有明确百分比，可以使用 Healthy/Caution/Critical；
- API 余额只有金额但没有预算上限时，不能自动判断健康程度；
- 当月消费高低取决于用户预算，不能只根据金额染红；
- 本地 Token 统计是估算，不应使用与官方额度相同的强警告色；
- Provider 品牌色与额度状态色必须分离。

建议将颜色分为两层：

```text
Provider 色：表示来源，例如 DeepSeek、OpenAI、Claude
Status 色：表示健康、注意、危险、过期、错误
```

状态色只应用在进度、轻微环境色和图标上，不要让品牌色与状态色互相覆盖。

## 7. 字体与数字

项目优先使用：

```text
SF Pro Display
Segoe UI Variable Display
系统 sans-serif
```

这是一个正确选择，因为它同时面向 macOS 和 Windows，且产品本身是系统级工具。

### 字体角色

| 内容 | 字重 | 特征 |
| --- | --- | --- |
| Provider / Plan | 600 | 大写，0.18em 字距 |
| 周期副标题 | 500 | 0.08em 字距 |
| 主数字 | 500 | 负字距，紧凑 |
| 周数字 | 400 | 轻于主数字 |
| 辅助文本 | 300-500 | 低对比 |
| 小控制 | 650-750 | 保证小尺寸下可读 |

### 数字处理值得借鉴

- 主数字使用 tabular 或近似稳定宽度，避免刷新时跳动；
- 百分号独立缩小，不与数字同尺寸；
- 主数字使用负字距，增加紧凑感；
- 数字不使用超粗字体，保持轻盈；
- 相对时间使用短句，不显示冗长日期。

对余额显示可以沿用这个结构：

```text
¥83.42
本月消费 ¥18.60
```

金额的小数部分可以比整数部分小 15%-25%，但不要像股票行情一样拆得过碎。

## 8. 动效系统

### 8.1 Aurora 漂移

背景层使用 18 秒的往返动画：

- 位移约 5%；
- 轻微放大；
- 旋转约 2°；
- 使用 `ease-in-out`；
- 无限 alternate。

这是一种环境动效。用户不会明确注意到它，但静态截图和实际运行之间会有生命感差异。

### 8.2 状态指示

正在消耗额度时，绿色状态点每 1.8 秒缓慢缩放并改变透明度。

这里的动画有清楚含义：额度正在发生变化。它不是装饰性呼吸灯。

### 8.3 数值进度

进度条宽度使用 0.5 秒 transition，刷新数据时不会突然跳变。

### 8.4 收起与展开

窗口根据 hover 在两种尺寸之间切换：

```text
100×100 -> 320×320
```

Orb 在闲置 2 秒后降到 70% 透明度，并增加背景模糊。用户再次 hover 时恢复。

![Quota Float 收起状态](https://raw.githubusercontent.com/change-42-yhmm/quota-float/main/docs/images/quota-orb.png)

### 8.5 无障碍降级

项目支持 `prefers-reduced-motion`：

- 停止 Aurora；
- 停止加载动画；
- 停止状态点脉冲；
- 移除进度条动画。

### 对 MiracleDeck 的改进建议

Quota Float 的 Aurora 即使在 Orb 状态下仍持续运行。对于目标为“低占用”的 MiracleDeck，建议：

- 收起状态使用静态背景；
- 面板关闭时停止全部动画；
- 展开并可见时才启动 Aurora；
- Aurora 周期放慢到 24-36 秒；
- 系统处于低电量模式时强制静态；
- 多卡片列表中只允许顶部摘要卡有环境动画；
- provider 列表项不使用持续动画；
- 严格支持减少动态效果。

## 9. 交互设计

### 9.1 Hover 作为渐进披露

默认只显示最重要的百分比，hover 后才展示：

- 套餐身份；
- 5 小时额度；
- 周额度；
- 重置时间；
- 重置机会；
- 控制按钮。

这是一种很有效的渐进披露方式，适合常驻桌面工具。

### 9.2 拖动区域

整个卡片本身可以拖动，顶部 header 使用 `cursor: move`。

因为窗口没有系统标题栏，这让卡片看起来更像一个真实桌面物件。

### 9.3 轻量控制

按钮没有文字标签，依赖：

- 图标；
- tooltip/title；
- aria-label；
- 一致的位置。

图标统一来自 Phosphor Icons，避免多个图标家族混用。

### 9.4 补充信息使用 Popover

重置机会的到期时间通过一个小型半透明浮层展示：

![重置机会到期信息](https://raw.githubusercontent.com/change-42-yhmm/quota-float/main/docs/images/quota-reset-expiration.png)

它没有长期占用主卡片空间，符合“默认只展示关键数据”的原则。

### 对 MiracleDeck 的适配

你的产品主要入口是菜单栏，不应完全依赖 hover。

建议保留两种表面：

1. 菜单栏 Popover：点击后稳定展开，适合查看多个 provider；
2. 可选 Floating Widget：沿用 Quota Float 的 Orb 与 hover 展开。

菜单栏版本不能因为鼠标移出某一行就收起整个面板。只有浮动小组件适合 hover 展开。

## 10. 状态设计

Quota Float 不只设计了成功状态，还覆盖：

- Loading；
- Stale；
- Stale 且超过 30 分钟；
- Unavailable；
- Signed out；
- Refresh failed；
- 数据正在刷新；
- 正在消耗额度。

错误状态不会显示 `0%`，因为 `0%` 会被误解成额度耗尽。它会替换整个主指标区域，显示图标、状态标题、说明和刷新按钮。

这是非常值得继承的原则：

> 缺失数据必须显示为未知或不可用，不能显示为零。

### MiracleDeck 应定义的状态

| 状态 | UI 表达 |
| --- | --- |
| Loading | 保留最终布局的骨架，不使用居中大转圈 |
| Fresh | 正常数据显示 |
| Refreshing | 保留旧数据，显示轻量刷新状态 |
| Stale | 保留最后成功数据，标注数据时间 |
| Expired | 不再把旧数字当成当前数字，进入过期界面 |
| Signed out | 明确指出需要重新登录哪个 provider |
| Permission denied | 区分普通 API Key 与 Admin Key 权限不足 |
| Rate limited | 显示下次重试时间 |
| Format changed | 告知上游接口可能变化，提供脱敏诊断 |
| Estimated | 明确标注“本地估算” |

## 11. 为什么它看起来精致

### 11.1 不是纯白卡片

浅蓝灰底色比纯白更柔和，也能承接冷暖渐变。

### 11.2 阴影非常弱

它没有依赖厚重阴影表现悬浮，而是使用内高光、透明边框和背景材质。

### 11.3 数字足够大，但不粗暴

64px 数字是绝对主角，但字重只有 500，不像金融行情或告警大屏。

### 11.4 背景状态是连续的

健康、注意、危险不是三个互不相关的主题，而是从冷色逐渐转向暖色。

### 11.5 控制被压到最低

按钮的大小、透明度和数量都受到控制。卡片首先是信息物件，其次才是可操作工具。

### 11.6 视觉落点完整

左上身份、中央数字、左下次指标、右下 Logo 构成一个稳定四角结构。

### 11.7 动效足够慢

18 秒的背景漂移没有明显起点和终点，避免廉价的“会动渐变”观感。

## 12. 设计中可以改进的地方

### 12.1 只适合单一主指标

320×320 的方形构图非常适合一个 provider，但 MiracleDeck 需要展示多个 API 余额和多个订阅套餐。如果每个 provider 都使用同尺寸方卡，面板会过长或需要频繁切换。

改进方式：

- 顶部保留一个 Quota Float 风格的选中 provider 摘要卡；
- 下方使用紧凑 provider 行；
- 点击 provider 行后切换顶部摘要；
- 支持收藏 1-2 个指标到菜单栏；
- 不为每个 provider 同时播放 Aurora。

### 12.2 Orb 缺少 provider 身份

Orb 只显示 `74%`。当以后支持多个 provider 时，用户可能不知道这个数字属于 Codex、Claude 还是其他服务。

改进方式：

- Orb 左上放 12-14px provider 小标志；
- 或使用极小的 provider 字母标识；
- 或让 Orb 颜色带有 provider 的弱品牌倾向；
- 多 provider 自动轮换时，切换必须有明确身份反馈。

### 12.3 Hover resize 可能产生窗口抖动

窗口从 100×100 直接变为 320×320。如果窗口锚点或屏幕边缘处理不稳定，可能出现：

- 展开后跑出屏幕；
- 鼠标相对窗口位置改变；
- 快速进入和离开造成闪烁；
- 多显示器缩放问题。

改进方式：

- 以距离最近的屏幕边缘为锚点扩展；
- 展开后加入 250-400ms 的收起延迟；
- 鼠标从 Orb 进入卡片时保持命中区域；
- 屏幕边缘自动翻转扩展方向；
- 在触摸板和辅助功能环境中提供点击锁定展开。

### 12.4 持续动画可能影响低占用目标

常驻窗口的无限渐变动画会持续触发合成。单个窗口成本可能不高，但它与“尽可能小的资源占用”存在方向冲突。

建议默认静态，只有面板展开时播放。

### 12.5 文本对比需要重新验证

部分辅助文本使用约 52% 的深色透明度，背景又是动态渐变。小字号文字可能在某些渐变位置低于理想对比度。

项目的 `prefers-contrast: more` 样式把部分辅助文字改为白色，但浅色背景上的白色也不一定更清晰。

MiracleDeck 应：

- 使用语义色 token，而不是直接用透明度；
- 在所有状态背景上测量 WCAG 对比度；
- 辅助文本至少保持稳定的深灰；
- 高对比模式切换到实色背景与高对比文字；
- 不让背景动画经过关键文本区域时大幅改变亮度。

### 12.6 缺少完整深色主题

当前视觉主要是浅色柔光。MiracleDeck 作为 macOS 菜单栏工具，应支持系统深色模式，但深色模式不能简单地把卡片改成黑色再保留原渐变。

建议深色主题使用：

- 冷灰蓝深表面；
- 低饱和环境色；
- 明亮但不纯白的主数字；
- 更弱的外阴影；
- 更清晰的内边框；
- 相同的状态色温逻辑。

## 13. MiracleDeck 推荐视觉方向

### 13.1 设计定位

> 一个像系统小组件一样安静、像专业监控工具一样可信的额度入口。

建议继承 Quota Float 的：

- 大数字优先；
- 柔和 Aurora；
- 大圆角；
- 低干扰控制；
- 状态色温；
- Orb 模式；
- 错误状态不伪造数据；
- 系统字体；
- Provider 标志落点。

不建议直接继承：

- 所有 provider 都使用 320×320 方卡；
- hover 是唯一展开方式；
- 动态背景始终运行；
- 只有浅色主题；
- Orb 不显示 provider 身份；
- API 余额和套餐百分比共享同一套状态规则。

### 13.2 两种界面模式

#### 菜单栏模式

建议宽度 360-390pt，高度根据 provider 数量变化。

```text
┌────────────────────────────────────┐
│ MiracleDeck              ↻   ⚙︎ │
│                                    │
│ ┌────────────────────────────────┐ │
│ │ CODEX · PLUS               ◉   │ │
│ │ 5 小时额度                     │ │
│ │ 74%                            │ │
│ │ ███████████████░░░░░           │ │
│ │ 1h 18m 后刷新 · 周额度 42%      │ │
│ └────────────────────────────────┘ │
│                                    │
│ DeepSeek API      ¥83.42      正常 │
│ OpenAI API        $18.60 本月      │
│ Claude Max        61%         3h后 │
│ My New API        ¥26.80      正常 │
│                                    │
│ 最后更新：刚刚                    │
└────────────────────────────────────┘
```

顶部选中卡使用柔光材质，下方 provider 使用紧凑行。这样既保留视觉特色，也能承载多个账户。

#### Floating Widget 模式

```text
收起：
┌────────┐
│ C 74%  │
└────────┘

展开：
┌──────────────────────────────┐
│ CODEX · PLUS              ◉  │
│ 74%                          │
│ ███████████████░░░░░         │
│ 1h 18m 后刷新                │
│ 周额度 42%                   │
└──────────────────────────────┘
```

Floating Widget 应是可选功能，菜单栏 Popover 才是默认入口。

## 14. MiracleDeck 设计 Token 建议

以下 token 用于建立相同气质，不是要求复制 Quota Float 的具体数值。

### 14.1 Light

```text
surface.base           冷灰白
surface.elevated       略带蓝的浅色表面
surface.glass          70%-86% 不透明度
text.primary           冷调近黑
text.secondary         稳定深灰，不依赖过低透明度
border.soft            半透明白 + 极淡冷灰
shadow.ambient         冷灰蓝低透明阴影
accent.info            柔和蓝
status.healthy         薄荷绿
status.caution         暖黄
status.critical        桃橙
status.stale           中性灰
status.error           低饱和红橙
```

### 14.2 Dark

```text
surface.base           冷调深灰蓝
surface.elevated       比基础表面亮一级
surface.glass          76%-90% 不透明度
text.primary           冷调近白
text.secondary         中高亮灰
border.soft            低透明白色内边框
shadow.ambient         更弱的外阴影
accent.info            亮度适中的蓝
```

### 14.3 尺寸

```text
menu width             360-390pt
menu outer radius      20-24pt
hero card radius       26-32pt
compact row radius     14-18pt
floating orb           72-84pt
orb radius             24-30pt
hero number            52-64pt
balance number         40-52pt
secondary number       24-30pt
button                 26-30pt
```

### 14.4 间距

```text
基础单位               4pt
小间距                 8pt
组件内间距             12pt
卡片内间距             20-24pt
主卡片边距             24-28pt
分组间距               16-20pt
```

## 15. SwiftUI 实现映射

虽然 Quota Float 使用 React、CSS 和 Tauri，但这套设计可以迁移到 SwiftUI。

### CSS 结构与 SwiftUI 对应

| Quota Float | SwiftUI |
| --- | --- |
| 透明无边框窗口 | `NSPanel` / `MenuBarExtra` |
| `border-radius` | `RoundedRectangle(cornerRadius:)` |
| `backdrop-filter` | `.background(.ultraThinMaterial)` |
| 多层 radial gradient | `ZStack` 中叠加多个 `RadialGradient` |
| Aurora drift | `TimelineView` 或低频状态动画 |
| 内高光 | `.overlay` 白色透明描边 |
| 弱阴影 | `.shadow(color:radius:y:)` |
| 百分比进度 | `GeometryReader` + Capsule |
| hover 展开 | `.onHover` + `NSPanel.setContentSize` |
| reduced motion | `@Environment(\.accessibilityReduceMotion)` |
| 高对比 | `@Environment(\.colorSchemeContrast)` |
| 深浅主题 | `@Environment(\.colorScheme)` |

### 低功耗实现注意

- 不要在菜单关闭时运行 `TimelineView`；
- 环境色动画帧率不需要达到 60fps；
- 可以每 1-2 秒更新一次渐变参数，并让系统插值；
- Orb 使用静态渐变；
- 多 provider 行不使用背景动画；
- 网络刷新与动画完全解耦；
- 数据变化时只动画数字和进度，不重绘整个列表。

## 16. 组件清单

建议为 MiracleDeck 建立以下设计组件：

```text
MonitorPopover
ProviderHeroCard
ProviderCompactRow
PrimaryMetric
SecondaryMetric
QuotaProgress
BalanceMetric
ResetCountdown
FreshnessLabel
ProviderMark
SemanticStatus
FloatingOrb
CredentialState
InlineDiagnostic
RefreshControl
ProviderSwitcher
```

组件职责必须清楚：

- `ProviderHeroCard` 负责当前选中 provider 的强视觉展示；
- `ProviderCompactRow` 负责多 provider 扫读；
- `QuotaProgress` 只展示有明确上限的额度；
- `BalanceMetric` 展示货币余额，不假设上限；
- `FreshnessLabel` 统一处理最后更新时间和 stale；
- `SemanticStatus` 不承担品牌识别；
- `ProviderMark` 不承担健康状态。

## 17. 设计约束

### 必须遵守

- 一个卡片一个主数字；
- 官方额度与本地估算必须有不同标签；
- 未知数据不能显示成 0；
- 套餐额度和 API 余额使用不同组件；
- 动态背景不能影响文字可读性；
- 小字号文字必须通过对比度检查；
- 动效必须支持减少动态效果；
- 浮动窗口必须能点击固定展开；
- 多显示器和屏幕边缘必须正确处理；
- 深色和浅色模式同时设计；
- 所有 provider 图标保持统一视觉尺寸，而不是统一图片像素尺寸。

### 应避免

- 每个 provider 一张大型渐变卡；
- 多种高饱和品牌色同时出现；
- 所有状态都使用发光圆点；
- 大面积红色危险背景；
- 过多胶囊 Badge；
- 每行都有进度条；
- 将余额变化伪装成 Token 消耗；
- 常驻运行多个无限动画；
- 纯粹为了“高级感”增加模糊和透明度；
- 直接复制 Quota Float 的配色、Logo 布局和完整组件结构。

## 18. 可以直接形成的设计决策

1. MiracleDeck 默认采用菜单栏 Popover；
2. 提供可选 Floating Widget；
3. Floating Widget 使用 Orb + 展开卡片；
4. 选中 provider 使用 Soft Aurora 主卡；
5. 其他 provider 使用紧凑列表；
6. 主卡只允许一个主指标；
7. 套餐显示百分比和刷新时间；
8. API 显示余额、期间消费和币种；
9. 数据状态与 provider 品牌分离；
10. 收起和后台状态停止持续动画；
11. 支持浅色、深色、高对比和减少动态效果；
12. 所有缺失或失败状态不显示伪造数值。

## 19. 版权与借鉴边界

Quota Float 使用 MIT License。可以研究和借鉴它的实现，也可以在遵守 MIT 条款的前提下复用代码。

本项目更适合采取以下方式：

- 借鉴信息层级和状态模型；
- 自己重新设计多 provider 结构；
- 自己定义颜色、尺寸和组件 token；
- 不直接复制 Logo、截图或完整 CSS；
- 如果复制了具体源码，应在对应文件中保留原版权与 MIT 许可；
- 在项目文档的 Inspirations 或 Acknowledgements 中注明 Quota Float。

## 20. 最终评价

Quota Float 的设计成熟度高于一般开源额度工具，原因主要有四个：

1. 它把额度数字当成视觉主体，而不是把所有数据平铺；
2. 它使用环境色表达状态，而不是使用粗暴告警色；
3. 它用 Orb 解决了常驻窗口对桌面空间的侵占；
4. 它认真设计了错误、过期、未登录和减少动态效果。

对 MiracleDeck 而言，最合理的方向不是复制它的 320×320 卡片，而是将它的视觉语言扩展成：

> 一张有温度的当前 provider 摘要卡，加上一组高效率的多 provider 列表，再配一个可选的桌面 Orb。

这既能保留 Quota Float 的精致感，也能适应官方 API、中转站、套餐额度和多账户共同存在的产品需求。

## 参考源码

- [Quota Float 仓库](https://github.com/change-42-yhmm/quota-float)
- [主卡片组件](https://github.com/change-42-yhmm/quota-float/blob/main/src/components/QuotaCard.tsx)
- [视觉样式](https://github.com/change-42-yhmm/quota-float/blob/main/src/styles.css)
- [主应用交互](https://github.com/change-42-yhmm/quota-float/blob/main/src/App.tsx)
- [设计调试面板](https://github.com/change-42-yhmm/quota-float/blob/main/src/components/DesignPlayground.tsx)
- [Tauri 窗口配置](https://github.com/change-42-yhmm/quota-float/blob/main/src-tauri/tauri.conf.json)
- [MIT License](https://github.com/change-42-yhmm/quota-float/blob/main/LICENSE)
