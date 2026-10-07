import SwiftUI
import AppKit
import ServiceManagement

/// Launch-at-login via `SMAppService` (macOS 13+).
enum LoginItem {
    static var isEnabled: Bool {
        SMAppService.mainApp.status == .enabled
    }

    /// Returns an error message when registering fails — macOS refuses when the
    /// app does not live in /Applications.
    static func set(enabled: Bool) -> String? {
        do {
            if enabled {
                if SMAppService.mainApp.status != .enabled { try SMAppService.mainApp.register() }
            } else {
                if SMAppService.mainApp.status == .enabled { try SMAppService.mainApp.unregister() }
            }
            return nil
        } catch {
            return error.localizedDescription
        }
    }
}

/// A hand-built About window — accessory apps get no standard "About" menu, and
/// the system panel cannot show the artwork credits the way this project needs.
@MainActor
final class AboutWindowController: NSObject, NSWindowDelegate {
    static let shared = AboutWindowController()

    private var window: NSWindow?

    func open() {
        if let window {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }
        let view = AboutView().environmentObject(LocalizationManager.shared)
        let controller = NSHostingController(rootView: view)
        let win = NSWindow(contentViewController: controller)
        win.title = "\(LocalizationManager.shared[.about])"
        win.styleMask = [.titled, .closable]
        win.setContentSize(NSSize(width: 420, height: 470))
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

struct AboutView: View {
    @EnvironmentObject private var locale: LocalizationManager

    private var version: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }

    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 16)

            if let icon = NSApp.applicationIconImage {
                Image(nsImage: icon)
                    .resizable()
                    .frame(width: 96, height: 96)
            }

            Text(locale[.appName])
                .font(.system(size: 24, weight: .bold))
                .padding(.top, 12)

            Text("\(locale[.versionLabel]) \(version)")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.top, 2)

            Text(locale[.aboutBody])
                .font(.callout)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 10)
                .padding(.horizontal, 34)

            Text(locale[.subtitle])
                .font(.caption)
                .foregroundStyle(.tertiary)
                .padding(.top, 6)

            Divider()
                .padding(.horizontal, 34)
                .padding(.vertical, 14)

            VStack(alignment: .leading, spacing: 8) {
                Text(locale[.creditsTitle])
                    .font(.caption.bold())
                Text(locale[.creditsBody])
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                Text(locale[.licenseTitle])
                    .font(.caption.bold())
                    .padding(.top, 2)
                Text(locale[.licenseBody])
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 34)

            Spacer(minLength: 12)

            Text(locale[.copyright])
                .font(.caption2)
                .foregroundStyle(.tertiary)
                .padding(.bottom, 16)
        }
        .frame(width: 420, height: 470)
        .background(Color(nsColor: .windowBackgroundColor))
    }
}
