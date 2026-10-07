# 白饭鱼 / BaifanYu v1.0.0 — Release Notes / 发布说明

| Item / 项目 | Detail / 详情 |
|---|---|
| Version / 版本 | 1.0.0 (first macOS release / 首个 macOS 版本) |
| Release Date / 发布日期 | October 7, 2026 / 2026 年 10 月 7 日 |
| Installer / 安装包 | `BaifanYu_V1.0.0.dmg` |
| Requirements / 系统要求 | macOS 14.0 or later (Apple Silicon & Intel) / macOS 14.0 或更高版本（Apple Silicon 与 Intel） |
| Size / 体积 | ~17 MB (all artwork and sounds bundled / 立绘与音效全部内置) |
| License / 许可 | MIT (code) — artwork is community fan art, non-commercial only / MIT（代码）—— 美术资源为社区同人创作，仅限非商业使用 |
| Ported from / 移植自 | [LIN428924379/baifanyu](https://github.com/LIN428924379/baifanyu) — Android 0.7 |

---

## English

**白饭鱼 / BaifanYu** — a rice-eating whale girl who lives on your Mac desktop. A tiny borderless window floats above everything: drag her anywhere, drop her at the left or right edge of the screen and she hangs there with only her head showing, so she never blocks what you are looking at.

> **Thank you, [@LIN428924379](https://github.com/LIN428924379).** This is a port of your Android app [白饭鱼 / baifanyu](https://github.com/LIN428924379/baifanyu). The concept, the character, the artwork and the interaction design are all yours — this release only re-implements the code for macOS. 感谢原作者把《白饭鱼》开源出来。

### What's new — the macOS version

This is the first macOS release, so everything is new. Compared with the Android original it keeps the whole behaviour set and adds a few things that only make sense on a Mac:

- 🖱️ **Drag** her anywhere — she tilts in the direction you are dragging
- 📌 **Perch on a screen edge** — drag her to the left or right edge and let go: she hangs there, head rotated 90°, only her head visible; drag her back in to make her float again
- 🙂 **Six expressions** per skin, swapped by clicking her (the whole artwork swaps, so there are no seams)
- 🎲 **Random expressions** — while she idles she changes face by herself every 18–75 s *(new on macOS)*; toggle in the menu bar or in Settings
- 💬 **Hover bubble** — rest the pointer on her and she stops wandering while a small bubble shows today's date, a live clock and a random kind word (16 per language) *(new on macOS)*
- 🛑 **Wandering pauses when you hover her** and resumes the moment the pointer leaves *(new on macOS)*
- 👗 **Two skins**: bowl-head (饭盆头) and maid outfit (女仆装)
- 🦆 **Rubber-duck squeak** on click — three real duck samples, can be turned off
- 🚶 **Idle wandering** — she crawls around on her own, and settles when you touch, drag, perch or hover her
- 🎚️ **Three sliders**: floating height (120–480 pt), head width while perched (56–160 pt), amount of motion (30–150 %)
- 🖱️ **Right-click / press-and-hold menu** on her body: skin · next expression · Settings · call her back
- 🧊 **Menu bar resident** — no Dock icon; her face sits in the status bar and everything is reachable from there (⌘, for Settings)
- 🚀 **Launch at login** support
- 🌐 **Trilingual UI**: English / 简体中文 / 繁體中文 (follows the system, or set it manually)
- 🔋 **Stops rendering when you cannot see her** — occluded, screens asleep or the session locked
- 🔒 **100% offline** — no network code, no analytics, no tracking, no account
- 📜 MIT licensed code, no third-party dependencies

### What changed from the Android app

| Android original | This macOS port |
|---|---|
| Foreground service + `TYPE_APPLICATION_OVERLAY` window | `NSPanel` (borderless, non-activating, `level = .floating`, joins all Spaces, works over full-screen apps) |
| "Grant *display over other apps*" permission | Not needed — no permission prompts at all |
| Persistent notification with 收回 / 设置 actions | Menu bar dropdown with the same actions (plus random-expression and launch-at-login toggles) |
| Settings screen in the app | Separate Settings window (⌘,) + a native About window |
| "Add to autostart / no battery restrictions" advice for MIUI/EMUI/ColorOS | Not needed — replaced by a proper launch-at-login toggle |
| — | Per-pixel click-through: the transparent margin around her never swallows a click meant for the app behind her |
| — | Hover bubble (date / live clock / kind word) and random self-expression changes |

The animation maths, the edge-snap threshold, the head-only perch crop and the wander timings are a direct port of the original — the owner's numbers, reproduced on macOS.

### Installation

1. Download `BaifanYu_V1.0.0.dmg` and open it
2. Drag **白饭鱼 / BaifanYu** into the **Applications** folder
3. Launch it — her face appears in the **menu bar** and she floats on the desktop
4. On first launch from the Applications folder, a copyright notice and a privacy notice are shown once

### How to use

- **Hold her and drag** anywhere; **drag to the left/right screen edge and let go** to hang her there
- **Click her** for another expression (and a squeak)
- **Rest the pointer on her** — she stops, and a bubble shows the date, the time and a kind word
- **Right-click her** (or press and hold) for skin / next expression / Settings / call her back
- The **menu bar fish** is home base: bring her out or call her back, switch skin, toggle squeak / wandering / random expressions, Settings (⌘,), About, Quit (⌘Q)

### Privacy

Completely offline. No network code at all — no analytics, no tracking, no account, no uploads. Her position, size, expressions and sounds are stored in the app's local preferences on this Mac only.

### Known limitations

- Inherited from the original: the six expressions were generated in separate passes, so the hair edge can shift by a pixel or two when she changes face, and her hair does not swing (no mesh deformation — only whole-body transforms)
- The trimmed margins around her are the only place where a click could still be swallowed instead of reaching the app behind her (a single-pixel edge case)
- Settings content is slightly taller than the window; the page scrolls
- macOS 14 or later is required

### Credits & license

- **Original Android app**: [LIN428924379/baifanyu](https://github.com/LIN428924379/baifanyu) — MIT, © 2026 LIN428924379. Concept, character, artwork and interaction design all belong to the original author
- **Artwork** (standing art + 6 expressions per skin): community fan art from the original project, **not** covered by MIT — personal, non-commercial use only
- **Duck squeaks**: [Mixkit](https://mixkit.co/free-sound-effects/duck/) (Mixkit Free License)
- **macOS code**: MIT, © 2026 Du Haoze — see [LICENSE](LICENSE)

---

## 中文

**白饭鱼 / BaifanYu** —— 一只吃白饭的鲸鱼娘，住在你的 Mac 桌面上。她以一个极小的无边框窗口浮在所有东西之上：按住她能拖到任意位置，拖到屏幕左右边缘松手，她就扒在边上、只露一个脑袋，绝不挡住你看的东西。

> **感谢原作者 [@LIN428924379](https://github.com/LIN428924379)。** 本版本是 Android 应用[《白饭鱼》](https://github.com/LIN428924379/baifanyu)的 macOS 移植。创意、角色形象、立绘和交互设计全部属于原作者，这次只是把代码为 macOS 重写了一遍。

### 新内容 —— macOS 版

这是首个 macOS 版本，所以全部都是新的。它完整保留了原 Android 版的行为，并加了几件只有在 Mac 上才成立的事：

- 🖱️ **拖拽** —— 拖到哪算哪，拖动时朝拖动方向倾斜
- 📌 **扒边** —— 拖到屏幕左右边缘松手，她扒在边上、头旋转 90°、只露一个脑袋；从边缘往里拖就回到悬空状态
- 🙂 **每套皮肤 6 个表情**，点她循环切换（整张立绘切换，没有接缝）
- 🎲 **随机换表情** —— 闲着的时候她自己每隔 18~75 秒换一个表情*（macOS 版新增）*；菜单栏和设置里都能开关
- 💬 **悬停气泡** —— 鼠标停在她身上，她就不动了，旁边浮出一个小气泡，写着今天的日期、实时走秒的时钟和一句随机的关心话（每种语言 16 句）*（macOS 版新增）*
- 🛑 **鼠标一放到她身上，自动溜达立刻暂停**，指针移开马上继续*（macOS 版新增）*
- 👗 **两套皮肤**：饭盆头 / 女仆装
- 🦆 **小黄鸭音效** —— 点击时随机播一个真实鸭叫，可关闭
- 🚶 **自动溜达** —— 闲着的时候她自己爬来爬去；碰她、拖她、扒边、鼠标停在她身上时不动
- 🎚️ **三档调节**：悬空大小（120–480 pt）、扒边时脑袋宽度（56–160 pt）、动态幅度（30–150 %）
- 🖱️ **右键 / 长按菜单**：皮肤 · 换表情 · 设置 · 收回她
- 🧊 **菜单栏常驻** —— 没有 Dock 图标，她的脸就在状态栏上，所有操作都在那里（⌘, 打开设置）
- 🚀 **支持登录时自动启动**
- 🌐 **三语界面**：English / 简体中文 / 繁體中文（跟随系统，也可手动指定）
- 🔋 **看不见她的时候真的停止渲染** —— 被遮挡、屏幕休眠、会话锁定时
- 🔒 **完全离线** —— 无网络代码、无统计、无追踪、不要账号
- 📜 MIT 开源代码，无第三方依赖

### 与 Android 原版的差异

| Android 原版 | 这个 macOS 版 |
|---|---|
| 前台服务 + `TYPE_APPLICATION_OVERLAY` 悬浮窗 | `NSPanel`（无边框、不抢焦点、`level = .floating`、跨所有桌面空间、全屏应用之上也能显示） |
| 需要授予「显示在其他应用上层」权限 | 不需要 —— 全程没有任何权限弹窗 |
| 常驻通知里的「收回 / 设置」 | 菜单栏下拉，动作一致（另加随机换表情、登录自启开关） |
| 应用内设置页 | 独立设置窗口（⌘,）+ 原生「关于」窗口 |
| 小米/华为/OPPO/vivo 要手动加自启动、关省电限制 | 不需要 —— 换成正经的「登录时自动启动」开关 |
| — | 像素级点击穿透：她周围的透明边距不会吞掉本该给后面 App 的点击 |
| — | 悬停气泡（日期 / 实时时钟 / 关心话）与自动换表情 |

动画数学、边缘吸附阈值、扒边时只画脑袋的裁切、溜达的节拍，都是原版的直接移植 —— 原作者定的数值，在 macOS 上原样复现。

### 安装方法

1. 下载 `BaifanYu_V1.0.0.dmg` 并打开
2. 把 **白饭鱼 / BaifanYu** 拖进**应用程序**文件夹
3. 启动 —— 她的脸出现在**菜单栏**，同时浮在桌面上
4. 首次从「应用程序」文件夹启动时，会展示一次版权声明与隐私声明

### 怎么玩

- **按住她拖**到任意位置；**拖到屏幕左右边缘松手**，她就扒在边上
- **点她一下**换一个表情（顺便吱一声）
- **鼠标停在她身上**：她停下不动，旁边浮出日期、时间和一句关心话
- **右键点她**（或长按）弹出：皮肤 / 换表情 / 设置 / 收回她
- **菜单栏的小鱼**是她的家：让她出现或收回、换皮肤、开关音效 / 溜达 / 随机换表情、设置（⌘,）、关于、退出（⌘Q）

### 隐私

完全离线。整个 App 没有任何网络代码 —— 无统计、无追踪、不要账号、不上传。她的位置、大小、表情和音效都只存在这台 Mac 的本地偏好设置里。

### 已知限制

- 继承自原版：6 张表情立绘是分两次独立生成的，所以换表情时头发边缘可能有一两个像素的抖动；头发是「硬」的，不会跟着甩（目前只有整体变换，没有网格形变）
- 她轮廓外的透明边距是目前唯一可能"吞掉"一次点击的地方（极端情况下的单像素边界）
- 设置页内容比窗口略高，是滚动列表
- 需要 macOS 14 或更高版本

### 致谢与许可

- **原 Android 应用**：[LIN428924379/baifanyu](https://github.com/LIN428924379/baifanyu) —— MIT，© 2026 LIN428924379。创意、角色、立绘、交互设计全部属于原作者
- **美术资源**（立绘 + 每套 6 个表情）：来自原项目的社区同人创作，**不在 MIT 许可范围内**，仅限个人非商业使用
- **小黄鸭音效**：[Mixkit](https://mixkit.co/free-sound-effects/duck/)（Mixkit Free License）
- **macOS 代码**：MIT，© 2026 Du Haoze —— 见 [LICENSE](LICENSE)
