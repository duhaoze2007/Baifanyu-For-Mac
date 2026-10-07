import SwiftUI
import AppKit

/// The settings window. A menu bar app has no `Settings` scene in an SPM build,
/// so the window is created and reused by hand.
@MainActor
final class SettingsWindowController: NSObject, NSWindowDelegate {
    static let shared = SettingsWindowController()

    private var window: NSWindow?

    func open() {
        if let window {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }
        let root = SettingsView()
            .environmentObject(LocalizationManager.shared)
            .environmentObject(PetController.shared)
        let controller = NSHostingController(rootView: root)
        let win = NSWindow(contentViewController: controller)
        win.title = "\(LocalizationManager.shared[.appName]) — \(LocalizationManager.shared[.settings])"
        win.styleMask = [.titled, .closable, .miniaturizable]
        win.setContentSize(NSSize(width: 580, height: 760))
        win.center()
        win.delegate = self
        win.isReleasedWhenClosed = false
        window = win
        win.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func windowWillClose(_ notification: Notification) {
        window = nil
    }
}

struct SettingsView: View {
    @EnvironmentObject private var locale: LocalizationManager
    @EnvironmentObject private var pet: PetController
    @State private var loginItemError: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                header
                statusBox
                sizeBox
                skinBox
                behaviourBox
                howToBox
                aboutBox
            }
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(width: 580, height: 760)
        .background(Color(nsColor: .windowBackgroundColor))
    }

    // MARK: - Header

    private var header: some View {
        HStack(alignment: .center, spacing: 14) {
            if let image = BundledImage.header {
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 78, height: 100)
            }
            VStack(alignment: .leading, spacing: 5) {
                Text(locale[.appName])
                    .font(.system(size: 26, weight: .bold))
                Text(locale[.tagline])
                    .font(.callout)
                    .foregroundStyle(.secondary)
                Text(locale[.subtitle])
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            Spacer(minLength: 0)
        }
    }

    // MARK: - Status & main actions

    private var statusBox: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 8) {
                    Circle()
                        .fill(pet.isRunning ? Color.green : Color.secondary.opacity(0.5))
                        .frame(width: 8, height: 8)
                    Text(statusLine)
                        .font(.callout)
                    Spacer()
                }
                Text(detailLine)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: 10) {
                    Button(pet.isRunning ? locale[.hideButton] : locale[.showButton]) {
                        pet.toggle()
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)

                    Button(locale[.testFaceButton]) {
                        pet.cycleExpression()
                    }
                    .controlSize(.large)
                    .disabled(!pet.isRunning)
                    Spacer()
                }
            }
            .padding(4)
        } label: {
            Label(locale[.statusSection], systemImage: "sparkles")
        }
    }

    private var statusLine: String {
        pet.isRunning ? locale[.statusRunning] : locale[.statusReady]
    }

    private var detailLine: String {
        var parts: [String] = []
        parts.append(pet.isRunning ? locale[.sheIsRunning] : locale[.sheIsResting])
        if pet.isRunning {
            parts.append(pet.isPerched
                         ? (pet.perchedOnRight ? locale[.statePerchRight] : locale[.statePerchLeft])
                         : locale[.stateHover])
        }
        let available = pet.availableExpressionCount
        parts.append(available > 0
                     ? String(format: locale[.facesLoaded], Int32(available))
                     : locale[.facesMissing])
        return parts.joined(separator: " · ")
    }

    // MARK: - Size & motion

    private var sizeBox: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 12) {
                Text(locale[.sizeHint])
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                sliderRow(title: locale[.hoverSize],
                          value: $pet.hoverHeight,
                          range: AppSettings.minHoverHeight...AppSettings.maxHoverHeight,
                          display: { "\(Int($0.rounded())) pt" })
                sliderRow(title: locale[.perchWidth],
                          value: $pet.perchWidth,
                          range: AppSettings.minPerchWidth...AppSettings.maxPerchWidth,
                          display: { "\(Int($0.rounded())) pt" })
                sliderRow(title: locale[.amplitudeLabel],
                          value: $pet.amplitude,
                          range: AppSettings.minAmplitude...AppSettings.maxAmplitude,
                          display: { "\(Int(($0 * 100).rounded()))%" })
            }
            .padding(4)
        } label: {
            Label(locale[.sizeSection], systemImage: "arrow.up.left.and.arrow.down.right")
        }
    }

    private func sliderRow(title: String, value: Binding<Double>,
                           range: ClosedRange<Double>, display: @escaping (Double) -> String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Text(title)
                Spacer()
                Text(display(value.wrappedValue))
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
            .font(.callout)
            Slider(value: value, in: range, step: 1)
        }
    }

    // MARK: - Skin

    private var skinBox: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 10) {
                Picker("", selection: $pet.skinIndex) {
                    ForEach(PetSkin.skins, id: \.index) { skin in
                        Text(locale[skin.nameKey]).tag(skin.index)
                    }
                }
                .labelsHidden()
                .pickerStyle(.segmented)
                Text(locale[.skinHint])
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(4)
        } label: {
            Label(locale[.skinSection], systemImage: "paintpalette")
        }
    }

    // MARK: - Behaviour

    private var behaviourBox: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 12) {
                toggleRow(title: locale[.wanderTitle], hint: locale[.wanderHint], isOn: $pet.wanderOn)
                Divider()
                toggleRow(title: locale[.soundTitle], hint: locale[.soundHint], isOn: $pet.soundOn)
            }
            .padding(4)
        } label: {
            Label(locale[.behaviourSection], systemImage: "figure.walk")
        }
    }

    private func toggleRow(title: String, hint: String, isOn: Binding<Bool>) -> some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                Text(hint)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Toggle("", isOn: isOn)
                .labelsHidden()
                .toggleStyle(.switch)
        }
    }

    // MARK: - How to play

    private var howToBox: some View {
        GroupBox {
            Text(locale[.howToBody])
                .font(.callout)
                .foregroundStyle(.secondary)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(4)
        } label: {
            Label(locale[.howToTitle], systemImage: "hand.point.up.left")
        }
    }

    // MARK: - About

    private var aboutBox: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(locale[.versionLabel])
                    Spacer()
                    Text("1.0.0")
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }
                .font(.callout)

                HStack {
                    Text(locale[.language])
                    Spacer()
                    Picker("", selection: languageBinding) {
                        ForEach(AppLanguage.allCases) { language in
                            Text(displayName(for: language)).tag(language)
                        }
                    }
                    .labelsHidden()
                    .frame(width: 190)
                }
                .font(.callout)

                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(locale[.launchAtLogin])
                        if let loginItemError {
                            Text(loginItemError)
                                .font(.caption)
                                .foregroundStyle(.red)
                        }
                    }
                    Spacer()
                    Toggle("", isOn: launchAtLoginBinding)
                        .labelsHidden()
                        .toggleStyle(.switch)
                }

                Divider()

                Text(locale[.creditsBody])
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                Text(locale[.licenseBody])
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                Text(locale[.notesBody])
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .fixedSize(horizontal: false, vertical: true)
                HStack {
                    Spacer()
                    Text(locale[.copyright])
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                    Spacer()
                }
                .padding(.top, 2)
            }
            .padding(4)
        } label: {
            Label(locale[.about], systemImage: "info.circle")
        }
    }

    private var languageBinding: Binding<AppLanguage> {
        Binding(
            get: { LocalizationManager.shared.language },
            set: { LocalizationManager.shared.language = $0 }
        )
    }

    private var launchAtLoginBinding: Binding<Bool> {
        Binding(
            get: { LoginItem.isEnabled },
            set: { newValue in
                loginItemError = LoginItem.set(enabled: newValue) ?? nil
            }
        )
    }

    private func displayName(for language: AppLanguage) -> String {
        switch language {
        case .system:
            let detected = AppLanguage.detectSystem()
            let suffix = detected == .simplifiedChinese ? " (简体)"
                : (detected == .traditionalChinese ? " (繁體)" : " (English)")
            return locale[.followSystem] + suffix
        case .english: return "English"
        case .simplifiedChinese: return "简体中文"
        case .traditionalChinese: return "繁體中文"
        }
    }
}
