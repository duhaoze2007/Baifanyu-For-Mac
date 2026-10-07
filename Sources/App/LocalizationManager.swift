import Foundation
import SwiftUI

enum AppLanguage: String, CaseIterable, Identifiable {
    case system = "system"
    case english = "en"
    case simplifiedChinese = "zh-Hans"
    case traditionalChinese = "zh-Hant"

    var id: String { rawValue }

    static func detectSystem() -> AppLanguage {
        let preferred = Locale.preferredLanguages.first ?? "en"
        if preferred.hasPrefix("zh-Hant") || preferred.hasPrefix("zh-TW") || preferred.hasPrefix("zh-HK") {
            return .traditionalChinese
        }
        if preferred.hasPrefix("zh") { return .simplifiedChinese }
        return .english
    }
}

enum L10nKey: String, CaseIterable {
    // Identity
    case appName, tagline, subtitle, menuBarTitle
    // Menu bar
    case showHer, hideHer, nextFace, skinMenu, settings, about, quit, launchAtLogin
    // Skins
    case skinBasin, skinMaid
    // Settings — size
    case sizeSection, sizeHint, hoverSize, perchWidth, amplitudeLabel
    // Settings — behaviour
    case behaviourSection, wanderTitle, wanderHint, soundTitle, soundHint
    // Settings — skin
    case skinSection, skinHint, tapToSwitch
    // Settings — actions
    case showButton, hideButton, testFaceButton, sheIsRunning, sheIsResting
    // Status
    case statusSection, statusRunning, statusReady, facesLoaded, facesMissing, stateHover, statePerchLeft, statePerchRight
    // How to play
    case howToTitle, howToBody
    // About
    case aboutBody, versionLabel, copyright, mitLicense, language, followSystem
    case creditsTitle, creditsBody, licenseTitle, licenseBody
    // First launch
    case firstRunCopyrightTitle, firstRunCopyrightBody, firstRunPrivacyTitle, firstRunPrivacyBody
    case agree, disagree
    // Misc
    case privacyTitle, privacyBody, loginItemFailed, notesTitle, notesBody
}

@MainActor
final class LocalizationManager: ObservableObject {
    static let shared = LocalizationManager()

    @Published var language: AppLanguage {
        didSet {
            AppSettings.languageOverride = (language == .system) ? nil : language.rawValue
            syncAppleLanguages()
        }
    }

    /// Language actually in use (resolves `.system`).
    var resolved: AppLanguage {
        language == .system ? AppLanguage.detectSystem() : language
    }

    private init() {
        if let saved = AppSettings.languageOverride, let lang = AppLanguage(rawValue: saved) {
            self.language = lang
        } else {
            self.language = .system
        }
        syncAppleLanguages()
    }

    /// Keep AppKit-level UI (standard panels) in sync with the in-app choice.
    private func syncAppleLanguages() {
        switch resolved {
        case .english, .system: UserDefaults.standard.removeObject(forKey: "AppleLanguages")
        case .simplifiedChinese: UserDefaults.standard.set(["zh-Hans"], forKey: "AppleLanguages")
        case .traditionalChinese: UserDefaults.standard.set(["zh-Hant"], forKey: "AppleLanguages")
        }
    }

    subscript(key: L10nKey) -> String {
        strings[key]?[resolved] ?? strings[key]?[.english] ?? key.rawValue
    }

    private let strings: [L10nKey: [AppLanguage: String]] = [
        // ---------------------------------------------------------------- Identity
        .appName: [.english: "BaifanYu", .simplifiedChinese: "白饭鱼", .traditionalChinese: "白飯魚"],
        .menuBarTitle: [.english: "BaifanYu", .simplifiedChinese: "白饭鱼", .traditionalChinese: "白飯魚"],
        .tagline: [.english: "A rice-eating whale girl, living on your Mac desktop",
                   .simplifiedChinese: "吃白饭的鲸鱼娘，挂在你的 Mac 桌面上",
                   .traditionalChinese: "吃白飯的鯨魚娘，掛在你的 Mac 桌面上"],
        .subtitle: [.english: "Offline · No uploads · No account",
                    .simplifiedChinese: "不联网 · 不上传 · 不要账号",
                    .traditionalChinese: "不聯網 · 不上傳 · 不要帳號"],

        // ---------------------------------------------------------------- Menu bar
        .showHer: [.english: "Bring her out", .simplifiedChinese: "让她出现", .traditionalChinese: "讓她出現"],
        .hideHer: [.english: "Call her back", .simplifiedChinese: "收回她", .traditionalChinese: "收回她"],
        .nextFace: [.english: "Another expression", .simplifiedChinese: "换一个表情", .traditionalChinese: "換一個表情"],
        .skinMenu: [.english: "Skin", .simplifiedChinese: "皮肤", .traditionalChinese: "皮膚"],
        .settings: [.english: "Settings…", .simplifiedChinese: "设置…", .traditionalChinese: "設定…"],
        .about: [.english: "About BaifanYu", .simplifiedChinese: "关于白饭鱼", .traditionalChinese: "關於白飯魚"],
        .quit: [.english: "Quit BaifanYu", .simplifiedChinese: "退出白饭鱼", .traditionalChinese: "結束白飯魚"],
        .launchAtLogin: [.english: "Launch at login", .simplifiedChinese: "登录时自动启动", .traditionalChinese: "登入時自動啟動"],

        // ---------------------------------------------------------------- Skins
        .skinBasin: [.english: "Bowl-head", .simplifiedChinese: "饭盆头", .traditionalChinese: "飯盆頭"],
        .skinMaid: [.english: "Maid outfit", .simplifiedChinese: "女仆装", .traditionalChinese: "女僕裝"],

        // ---------------------------------------------------------------- Size & motion
        .sizeSection: [.english: "Size & motion", .simplifiedChinese: "调节", .traditionalChinese: "調節"],
        .sizeHint: [.english: "Two separate sizes: while floating it is her overall height, while she hangs on a screen edge only her head shows — that one is the head width.",
                    .simplifiedChinese: "大小分两处：悬空时看整体高度，扒在边上时只有脑袋露出来、看的是脑袋宽度。",
                    .traditionalChinese: "大小分兩處：懸空時看整體高度，扒在邊上時只有腦袋露出來、看的是腦袋寬度。"],
        .hoverSize: [.english: "Floating height", .simplifiedChinese: "悬空大小", .traditionalChinese: "懸空大小"],
        .perchWidth: [.english: "Head width while perched", .simplifiedChinese: "扒边时脑袋宽度", .traditionalChinese: "扒邊時腦袋寬度"],
        .amplitudeLabel: [.english: "Amount of motion", .simplifiedChinese: "动态幅度", .traditionalChinese: "動態幅度"],

        .behaviourSection: [.english: "Behaviour", .simplifiedChinese: "行为", .traditionalChinese: "行為"],
        .wanderTitle: [.english: "Wander around", .simplifiedChinese: "自动溜达", .traditionalChinese: "自動溜達"],
        .wanderHint: [.english: "She crawls around on her own when idle (never while you touch, drag or perch her)",
                      .simplifiedChinese: "闲着的时候她自己爬来爬去（碰她、拖她、趴边时不动）",
                      .traditionalChinese: "閒著的時候她自己爬來爬去（碰她、拖她、趴邊時不動）"],
        .soundTitle: [.english: "Rubber-duck squeak", .simplifiedChinese: "小黄鸭音效", .traditionalChinese: "小黃鴨音效"],
        .soundHint: [.english: "Click her and she squeaks", .simplifiedChinese: "点她一下，吱一声", .traditionalChinese: "點她一下，吱一聲"],

        // ---------------------------------------------------------------- Skin section
        .skinSection: [.english: "Skin", .simplifiedChinese: "皮肤", .traditionalChinese: "皮膚"],
        .skinHint: [.english: "Two looks, 6 expressions each", .simplifiedChinese: "两套形象，每套 6 个表情",
                    .traditionalChinese: "兩套形象，每套 6 個表情"],
        .tapToSwitch: [.english: "Click to switch", .simplifiedChinese: "点击切换", .traditionalChinese: "點擊切換"],

        // ---------------------------------------------------------------- Actions
        .showButton: [.english: "Bring her out", .simplifiedChinese: "让她出现", .traditionalChinese: "讓她出現"],
        .hideButton: [.english: "Call her back", .simplifiedChinese: "收回她", .traditionalChinese: "收回她"],
        .testFaceButton: [.english: "Try an expression", .simplifiedChinese: "试一下换表情", .traditionalChinese: "試一下換表情"],
        .sheIsRunning: [.english: "She is with you. Drag her to the left or right edge of the screen and let go — she will hang there.",
                        .simplifiedChinese: "她正在陪你。拖到屏幕左右边缘松手，她会扒在边上。",
                        .traditionalChinese: "她正在陪你。拖到螢幕左右邊緣放手，她會扒在邊上。"],
        .sheIsResting: [.english: "Ready. Press the button below to let her out.",
                        .simplifiedChinese: "已就绪，点下面的按钮让她出现。",
                        .traditionalChinese: "已就緒，點下面的按鈕讓她出現。"],

        // ---------------------------------------------------------------- Status
        .statusSection: [.english: "Her", .simplifiedChinese: "她的状态", .traditionalChinese: "她的狀態"],
        .statusRunning: [.english: "Status: with you", .simplifiedChinese: "状态：正在陪你", .traditionalChinese: "狀態：正在陪你"],
        .statusReady: [.english: "Status: resting", .simplifiedChinese: "状态：休息中", .traditionalChinese: "狀態：休息中"],
        .facesLoaded: [.english: "Artwork loaded: %d / 6 expressions",
                       .simplifiedChinese: "表情素材：已加载 %d / 6",
                       .traditionalChinese: "表情素材：已載入 %d / 6"],
        .facesMissing: [.english: "No expression artwork found — the app bundle is incomplete.",
                        .simplifiedChinese: "表情素材没加载成功 —— 应用包不完整。",
                        .traditionalChinese: "表情素材沒載入成功 —— 應用程式包不完整。"],
        .stateHover: [.english: "floating", .simplifiedChinese: "悬空中", .traditionalChinese: "懸空中"],
        .statePerchLeft: [.english: "hanging on the left edge", .simplifiedChinese: "扒在左边缘", .traditionalChinese: "扒在左邊緣"],
        .statePerchRight: [.english: "hanging on the right edge", .simplifiedChinese: "扒在右边缘", .traditionalChinese: "扒在右邊緣"],

        // ---------------------------------------------------------------- How to play
        .howToTitle: [.english: "How to play", .simplifiedChinese: "怎么玩", .traditionalChinese: "怎麼玩"],
        .howToBody: [.english: "· Hold her and drag anywhere\n· Drag to the left or right edge of the screen and let go — she hangs there, only her head showing\n· Drag her back from the edge to make her float again\n· Click her for another expression\n· Right-click her (or press and hold) for skin / settings / call her back",
                     .simplifiedChinese: "· 按住她，拖到任意位置\n· 拖到屏幕左右边缘松手 —— 她会扒在边上，只露一个脑袋看着你\n· 从边缘往外拖，回到悬空状态\n· 点她一下，换一个表情\n· 右键点她（或长按）弹出「皮肤 / 设置 / 收回」",
                     .traditionalChinese: "· 按住她，拖到任意位置\n· 拖到螢幕左右邊緣放手 —— 她會扒在邊上，只露一個腦袋看著你\n· 從邊緣往外拖，回到懸空狀態\n· 點她一下，換一個表情\n· 右鍵點她（或長按）彈出「皮膚 / 設定 / 收回」"],

        // ---------------------------------------------------------------- About
        .aboutBody: [.english: "A tiny whale girl who floats on your desktop, eats white rice and squeaks when poked.",
                     .simplifiedChinese: "一只浮在你桌面上的鲸鱼娘，吃白饭，戳一下会吱一声。",
                     .traditionalChinese: "一隻浮在你桌面上的鯨魚娘，吃白飯，戳一下會吱一聲。"],
        .versionLabel: [.english: "Version", .simplifiedChinese: "版本", .traditionalChinese: "版本"],
        .copyright: [.english: "macOS port © 2026 Du Haoze · MIT License",
                     .simplifiedChinese: "macOS 版 © 2026 Du Haoze · MIT License",
                     .traditionalChinese: "macOS 版 © 2026 Du Haoze · MIT License"],
        .mitLicense: [.english: "Original Android app by LIN428924379 (MIT). Artwork belongs to its community authors and is not covered by the MIT license.",
                      .simplifiedChinese: "原 Android 应用由 LIN428924379 创作（MIT）。美术资源属于社区同人创作，不在 MIT 许可范围内。",
                      .traditionalChinese: "原 Android 應用由 LIN428924379 創作（MIT）。美術資源屬於社群同人創作，不在 MIT 授權範圍內。"],
        .language: [.english: "Language", .simplifiedChinese: "语言", .traditionalChinese: "語言"],
        .followSystem: [.english: "Follow System", .simplifiedChinese: "跟随系统", .traditionalChinese: "跟隨系統"],
        .creditsTitle: [.english: "Credits", .simplifiedChinese: "素材与致谢", .traditionalChinese: "素材與致謝"],
        .creditsBody: [.english: "Whale girl character from the DeepSeek community; standing art & expressions generated with AI and cut out by the original author; duck squeaks from Mixkit (Mixkit Free License).",
                       .simplifiedChinese: "角色形象来自 DeepSeek 社区同人创作；立绘与表情由 AI 生成、原作者后期对齐去背；小黄鸭音效来自 Mixkit（Mixkit Free License）。",
                       .traditionalChinese: "角色形象來自 DeepSeek 社群同人創作；立繪與表情由 AI 生成、原作者後期對齊去背；小黃鴨音效來自 Mixkit（Mixkit Free License）。"],
        .licenseTitle: [.english: "License", .simplifiedChinese: "许可证", .traditionalChinese: "授權"],
        .licenseBody: [.english: "Code: MIT. Artwork: personal, non-commercial use only.",
                       .simplifiedChinese: "代码：MIT。美术资源：仅限个人非商业使用。",
                       .traditionalChinese: "程式碼：MIT。美術資源：僅限個人非商業使用。"],

        // ---------------------------------------------------------------- First launch
        .firstRunCopyrightTitle: [.english: "Copyright Notice", .simplifiedChinese: "版权声明", .traditionalChinese: "版權聲明"],
        .firstRunCopyrightBody: [.english: "macOS version © 2026 Du Haoze. All rights reserved.\n\nThe code is licensed under the MIT License. The character artwork comes from the original Android app 白饭鱼 by LIN428924379 — community fan art, not covered by MIT, for personal non-commercial use only. Please do not use the artwork commercially.",
                                 .simplifiedChinese: "macOS 版 © 2026 Du Haoze. 保留所有权利。\n\n代码采用 MIT License 开源许可。角色美术资源来自原作者 LIN428924379 的 Android 应用《白饭鱼》—— 属于社区同人创作，不在 MIT 许可范围内，仅限个人非商业使用。请勿将美术资源用于商业用途。",
                                 .traditionalChinese: "macOS 版 © 2026 Du Haoze. 保留所有權利。\n\n程式碼採用 MIT License 開源授權。角色美術資源來自原作者 LIN428924379 的 Android 應用《白飯魚》—— 屬於社群同人創作，不在 MIT 授權範圍內，僅限個人非商業使用。請勿將美術資源用於商業用途。"],
        .firstRunPrivacyTitle: [.english: "Privacy Notice", .simplifiedChinese: "隐私声明", .traditionalChinese: "隱私聲明"],
        .firstRunPrivacyBody: [.english: "BaifanYu is completely offline. It has no network code at all: no analytics, no tracking, no account, no uploads.\n\nEverything — her position, size, expressions and squeaks — stays on this Mac, stored in your local preferences.",
                              .simplifiedChinese: "白饭鱼完全离线运行。它没有任何网络代码：无统计、无追踪、不要账号、不上传。\n\n她的位置、大小、表情和音效全部保留在这台 Mac 上，存放在本地偏好设置里。",
                              .traditionalChinese: "白飯魚完全離線執行。它沒有任何網路程式碼：無統計、無追蹤、不要帳號、不上傳。\n\n她的位置、大小、表情和音效全部保留在這台 Mac 上，存放在本地偏好設定裡。"],
        .agree: [.english: "Agree", .simplifiedChinese: "同意", .traditionalChinese: "同意"],
        .disagree: [.english: "Disagree", .simplifiedChinese: "不同意", .traditionalChinese: "不同意"],

        // ---------------------------------------------------------------- Misc
        .privacyTitle: [.english: "Privacy", .simplifiedChinese: "隐私", .traditionalChinese: "隱私"],
        .privacyBody: [.english: "Offline by design: no network, no analytics, no account.",
                       .simplifiedChinese: "完全离线：无网络、无统计、不要账号。",
                       .traditionalChinese: "完全離線：無網路、無統計、不要帳號。"],
        .loginItemFailed: [.english: "Could not change the login item — move the app to /Applications first.",
                           .simplifiedChinese: "无法修改登录项 —— 请先把 App 拖到「应用程序」文件夹。",
                           .traditionalChinese: "無法修改登入項 —— 請先把 App 拖到「應用程式」資料夾。"],
        .notesTitle: [.english: "Notes", .simplifiedChinese: "小提示", .traditionalChinese: "小提示"],
        .notesBody: [.english: "She has no Dock icon — the menu bar fish is her home. Closing this window leaves her on your desktop; quit from the menu bar or with ⌘Q.",
                     .simplifiedChinese: "她没有 Dock 图标 —— 菜单栏那只小鱼就是她的家。关掉这个窗口她还在桌面上，从菜单栏或 ⌘Q 退出。",
                     .traditionalChinese: "她沒有 Dock 圖示 —— 選單列那隻小魚就是她的家。關掉這個視窗她還在桌面上，從選單列或 ⌘Q 離開。"],
    ]
}
