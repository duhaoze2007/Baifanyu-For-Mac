import SwiftUI
import AppKit

@main
struct BaifanYuApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var pet = PetController.shared
    @StateObject private var locale = LocalizationManager.shared

    init() {
        // App.init() is guaranteed to run (applicationDidFinishLaunching is not
        // reliably delivered in a MenuBarExtra-only app), so she is started here.
        // PetController.start() is idempotent.
        PetController.shared.start()
    }

    var body: some Scene {
        MenuBarExtra {
            MenuBarView()
                .environmentObject(locale)
                .environmentObject(pet)
        } label: {
            MenuBarIconLabel()
        }
        .menuBarExtraStyle(.menu)
    }
}

/// Her face in the menu bar — the artwork itself, not an SF Symbol.
struct MenuBarIconLabel: View {
    var body: some View {
        if let image = BundledImage.menuBarIcon {
            Image(nsImage: image)
                .renderingMode(.original)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 24, height: 24)
        } else {
            Image(systemName: "fish.fill")
        }
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        PetController.shared.start()
        // Let the menu bar item come alive before any modal alert appears.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            self.showFirstLaunchDialogsIfNeeded()
        }
    }

    /// Nothing to keep alive: she is an accessory app and quits only on request.
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }

    // MARK: - First-launch dialogs

    private func showFirstLaunchDialogsIfNeeded() {
        // Only for copies launched from /Applications — dev copies stay silent.
        guard Bundle.main.bundlePath.hasPrefix("/Applications/") else { return }
        let key = "BaifanYu_FirstRun_" + Bundle.main.bundlePath
        guard !UserDefaults.standard.bool(forKey: key) else { return }
        let locale = LocalizationManager.shared

        let copyright = NSAlert()
        copyright.messageText = locale[.firstRunCopyrightTitle]
        copyright.informativeText = locale[.firstRunCopyrightBody]
        copyright.alertStyle = .informational
        copyright.icon = NSImage(systemSymbolName: "lock.shield.fill", accessibilityDescription: nil)
        copyright.addButton(withTitle: locale[.agree])
        copyright.addButton(withTitle: locale[.disagree])
        guard copyright.runModal() == .alertFirstButtonReturn else {
            NSApp.terminate(nil)
            return
        }

        let privacy = NSAlert()
        privacy.messageText = locale[.firstRunPrivacyTitle]
        privacy.informativeText = locale[.firstRunPrivacyBody]
        privacy.alertStyle = .informational
        privacy.icon = NSImage(systemSymbolName: "hand.raised.fill", accessibilityDescription: nil)
        privacy.addButton(withTitle: locale[.agree])
        privacy.addButton(withTitle: locale[.disagree])
        guard privacy.runModal() == .alertFirstButtonReturn else {
            NSApp.terminate(nil)
            return
        }

        UserDefaults.standard.set(true, forKey: key)
    }
}
