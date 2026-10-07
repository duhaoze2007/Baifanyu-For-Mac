<p align="center">
  <img src="docs/icon.png" width="128" alt="白饭鱼 / BaifanYu">
</p>

<h1 align="center">白饭鱼 / BaifanYu</h1>

<p align="center">
  A rice-eating whale girl who lives on your Mac desktop
  <br>
  <b>Native Swift · Offline · No account · MIT code</b>
</p>

<p align="center">
  <i>A macOS port of the Android desktop pet
  <a href="https://github.com/LIN428924379/baifanyu">白饭鱼 / baifanyu</a> by
  <a href="https://github.com/LIN428924379">LIN428924379</a></i>
  <br>
  <b>Thank you, LIN428924379 — the original idea, the character, the artwork and the
  interaction design are all yours. 感谢原作者，这个移植只是把你的作品搬到了 Mac 上。</b>
</p>

---

## What she is / 她是什么

She floats on your desktop as a tiny borderless window. Drag her anywhere; drop her at the left or right edge of the screen and she hangs there with only her head showing, so she never blocks what you are looking at. Click her for another expression and a rubber-duck squeak. Rest the pointer on her and she stops, showing a bubble with the date, a live clock and a random kind word; leave her alone and she wanders a little and changes expression by herself now and then.

她以一个极小的无边框窗口浮在桌面上。按住她可以拖到任意位置；拖到屏幕左右边缘松手，她会扒在边上、只露一个脑袋，绝不挡住你看的东西。点她一下换一个表情，顺便吱一声（小黄鸭音效）。鼠标停在她身上她就不动了，旁边浮出一个小气泡写着日期、时间和一句随机的关心话；没人理她的时候她会自己爬两下、时不时自己换个表情。

<p align="center">
  <img src="docs/expressions.png" width="760" alt="standing art + six expressions">
</p>

---

## Features / 功能

- **Floats on top** of every app, on every Space, over full-screen windows
- **Drag** her anywhere — she tilts in the direction you are dragging
- **Perch on a screen edge** — drag her to the left or right edge and let go: she hangs there, head rotated 90°, only her head visible
- **Six expressions** per skin, cycled by clicking her (whole artwork swaps, so no seams)
- **Random expressions** — while she idles she changes face by herself every 18–75 s (menu bar + Settings toggle)
- **Rest the pointer on her** and she stops wandering; a bubble appears with today's date, a live clock and a random kind word — move the pointer away and she carries on
- **Two skins**: bowl-head (饭盆头) and maid outfit (女仆装)
- **Rubber-duck squeak** on click, three real duck samples, can be switched off
- **Idle wandering** — she crawls around on her own; she stops when you touch, drag, perch her, or leave the pointer resting on her
- **Three size sliders**: floating height, head width while perched, amount of motion
- **Right-click menu** on her body: skin / next expression / settings / call her back
- **Menu bar resident**, no Dock icon — her face sits in the menu bar
- **Launch at login** support
- **Stops rendering when you cannot see her** (occluded, screens asleep, session locked)
- **Trilingual UI**: English / 简体中文 / 繁體中文 (follows the system or a manual override)
- **100 % offline** — no network code at all: no analytics, no tracking, no account
- **MIT licensed code**, no third-party dependencies

---

- **浮在所有 App 之上**，所有桌面空间、全屏窗口上都在
- **拖拽** —— 拖到哪算哪，拖动时朝拖动方向倾斜
- **扒边** —— 拖到屏幕左右边缘松手，她扒在边上、头旋转 90°、只露一个脑袋
- **每套皮肤 6 个表情**，点她循环切换（整张立绘切换，没有接缝）
- **随机换表情** —— 闲着的时候她自己每隔 18~75 秒换一个表情（菜单栏 + 设置里都能开关）
- **鼠标停在她身上**：她就不走了，旁边浮出一个小气泡，写今天的日期、实时的时间和一句随机的关心话；鼠标移开她就继续
- **两套皮肤**：饭盆头 / 女仆装
- **小黄鸭音效**：点击时随机播一个真实鸭叫，可关
- **自动溜达** —— 闲着的时候她自己爬来爬去；碰她、拖她、趴边、鼠标停在她身上时不动
- **三档调节**：悬空大小 / 扒边时脑袋宽度 / 动态幅度
- **右键菜单**：皮肤 / 换表情 / 设置 / 收回她
- **菜单栏常驻**，没有 Dock 图标 —— 她的脸就在菜单栏上
- **支持登录时自动启动**
- **看不见她的时候真的停止渲染**（被遮挡、屏幕休眠、会话锁定时）
- **三语界面**：English / 简体中文 / 繁體中文（跟随系统或手动切换）
- **完全离线**：没有任何网络代码，无统计、无追踪、不要账号
- **MIT 开源代码**，无第三方依赖

---

## Requirements / 系统要求

- macOS 14.0 or later / macOS 14.0 或更高版本
- Apple Silicon or Intel / Apple Silicon 或 Intel
- No Xcode needed — Command Line Tools are enough / 无需 Xcode，装了 Command Line Tools 即可

## Build / 构建

```bash
bash build.sh          # → BaifanYu.app
open BaifanYu.app
```

The script builds in release mode, bundles the artwork, sounds and the app icon, and ad-hoc signs the result. `build.sh` also picks a working SDK automatically: on a Command Line Tools-only toolchain the newest SDK declares SwiftUI's property wrappers as macros whose plugin lives only inside Xcode, so the script falls back to the newest SDK where that is not the case.

脚本以 release 模式构建，把立绘、音效、图标全部打进 `BaifanYu.app` 并完成 ad-hoc 签名。`build.sh` 还会自动挑选可用的 SDK：在只装 Command Line Tools 的机器上，最新 SDK 会把 SwiftUI 的属性包装器声明成宏，而宏插件只随 Xcode 提供，所以脚本会自动回退到不启用宏的 SDK。

Extra scripts / 附带脚本:

```bash
swift scripts/gen_icon.swift            # 1024² app icon        → icon-src/AppIcon_1024.png
swift scripts/gen_menubar_icon.swift    # menu bar face (colour) → Sources/Resources/MenuBarIcon.png
swift scripts/gen_expressions.swift     # README montage         → docs/expressions.png
bash scripts/make_dmg.sh                # distributable disk image
```

---

## How to use / 怎么用

1. `open BaifanYu.app` — the first time, the system asks nothing and she simply appears
2. **Hold her and drag** to move her; **drag to the left or right screen edge and let go** to make her hang there
3. **Click her** for another expression (and a squeak)
4. **Rest the pointer on her** — she stops, and a bubble shows the date, a live clock and a random kind word; move away and she keeps wandering
5. **Right-click her** (or press and hold) for skin / next expression / settings / call her back
6. Her face in the **menu bar** is home base: bring her out or call her back, switch skin, toggle the squeak, the wandering and the random expressions, open **Settings (⌘,)** or **About**
7. Closing the settings window leaves her on your desktop — quit from the menu bar or with **⌘Q**

---

## macOS port notes / 移植说明

The Android original is a foreground service with a `TYPE_APPLICATION_OVERLAY` window. On macOS the equivalent is an **`NSPanel`** with `.nonactivatingPanel`, borderless, transparent, `level = .floating`, `collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]`. It cannot become key, so clicking her never steals focus from what you are typing in.

Three things from the original's "three hard rules for floating windows" carry over and are implemented:

| Android rule | macOS equivalent |
|---|---|
| The window must hug the pet, never a full-screen transparent layer | the panel is resized to exactly her bounding box, per state |
| The window must be non-focusable | `NSPanel` + `.nonactivatingPanel` + `canBecomeKey = false` |
| Rendering must really stop when invisible | the 60 Hz timer is torn down on occlusion, screen sleep and session lock |

Per-pixel click-through is added on top: a global + local mouse monitor toggles `ignoresMouseEvents` depending on the alpha of the pixel under the pointer, so the transparent margin around her does not swallow clicks meant for the app behind her.

The geometry is a direct port of the Android `PetView` — the same floating bob (`0.022 · amp · sin(2πt/2.4)`), the same breathing squash, the same drag tilt, the same `min(56 pt, width × 25 %)` edge-snap threshold, the same head-only crop while perched, and the same idle-wander numbers (4 pt per 16 ms tick, 0.8 s settle, 1.2–3.6 s rest, 5 s after a touch). `dp` becomes points ~1:1, so the sliders keep their original ranges (120–480 / 56–160 / 30–150 %) and the defaults (240 / 96 / 75 %).

While she hangs on an edge, the same artwork is reused: rotated 90° and cropped to her head, exactly as on Android — no extra "perched" asset is needed.

---

## Project structure / 项目结构

```
Sources/
  App/
    BaifanYuApp.swift        @main, menu bar extra, first-launch dialogs
    AppSettings.swift        UserDefaults-backed settings (same keys & numbers as Android)
    LocalizationManager.swift 三语 UI strings
  Pet/
    PetSkin.swift            the two skins + their head-crop ratios
    PetBitmap.swift          pre-scaled / pre-rotated artwork + alpha hit testing
    PetView.swift            drawing, animation, mouse handling
    PetController.swift      panel, drag, edge snap, perch, wander, menu, sounds
    DuckSound.swift          duck squeak pool (AVAudioPlayer)
  Views/
    MenuBarView.swift        the menu bar dropdown
    SettingsView.swift       the settings window
    AboutWindow.swift        About window, launch-at-login helper
    HoverBubble.swift        the hover bubble (date / clock / kind word)
    BundledImage.swift       resource lookup
  Resources/                 artwork + duck samples + icon
```

---

## Credits & thanks / 致谢与许可

### Thank you / 特别感谢

**This project is a port. Nothing here would exist without
[LIN428924379/baifanyu](https://github.com/LIN428924379/baifanyu) — the original Android app by
[@LIN428924379](https://github.com/LIN428924379).**

**All credit for the concept, the character, the artwork and the interaction design belongs to
the original author. The macOS port reuses their artwork, their interaction design and their
animation maths, and only re-implements the code for macOS. Thank you for building it and for
releasing it under the MIT license. 感谢原作者把《白饭鱼》开源出来 —— 这个 macOS 版只是把她的家从手机
搬到了 Mac 上，创意、角色、立绘、动作设计全部属于原作者。**

### What comes from where / 各部分出处

| Part / 部分 | Origin / 出处 |
|---|---|
| Original app, concept, interaction design / 原应用、创意、交互设计 | [LIN428924379/baifanyu](https://github.com/LIN428924379/baifanyu) (MIT) |
| Standing art & 6 expressions per skin / 立绘与 6 个表情 | The original author's assets (community fan art, **not** MIT) / 原作者的素材（社区同人创作，**不在 MIT 范围**） |
| Duck squeaks / 小黄鸭音效 | [Mixkit](https://mixkit.co/free-sound-effects/duck/) (Mixkit Free License) |
| Character / 角色形象 | DeepSeek-community whale girl, as delivered with the original app / 随原应用提供的 DeepSeek 社区鲸鱼娘 |
| macOS code (SwiftUI + AppKit) / macOS 代码 | This repository, MIT, © 2026 Du Haoze |
| macOS support / 本移植 | © 2026 [Du Haoze](https://github.com/duhaoze2007) |

### License / 许可证

- **Code**: MIT — see [LICENSE](LICENSE) (keeps the original copyright notice alongside this port's)
- **Artwork** (`Sources/Resources/*.png`, `docs/`): community fan art from the original project, **not** covered by MIT — personal, non-commercial use only
- **代码**：MIT —— 见 [LICENSE](LICENSE)（许可证里同时保留了原作者和本移植的版权声明）
- **美术资源**（`Sources/Resources/*.png`、`docs/`）：来自原项目的社区同人创作，**不在 MIT 许可范围内**，仅限个人非商业使用

macOS version © 2026 Du Haoze · Original Android app © 2026 LIN428924379
