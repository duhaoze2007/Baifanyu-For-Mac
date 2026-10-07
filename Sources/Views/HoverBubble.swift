import SwiftUI
import AppKit

/// Live content of the hover bubble.
@MainActor
final class HoverBubbleModel: ObservableObject {
    @Published var dateText = ""
    @Published var timeText = ""
    @Published var sentence = ""
}

/// The bubble that appears when the pointer rests on her: today's date, a live
/// clock, and a random kind word.
///
/// It is a separate non-activating panel that ignores mouse events entirely, so
/// it never steals a click from whatever is underneath.
@MainActor
final class HoverBubble {
    static let size = NSSize(width: 268, height: 104)

    let model = HoverBubbleModel()
    private var panel: HoverBubblePanel?
    private var hostingView: NSHostingView<HoverBubbleView>?

    var isVisible: Bool { panel?.isVisible ?? false }

    private func makePanelIfNeeded() {
        guard panel == nil else { return }
        let view = HoverBubbleView(model: model)
        let hosting = NSHostingView(rootView: view)
        hosting.frame = NSRect(origin: .zero, size: Self.size)

        let newPanel = HoverBubblePanel(contentRect: NSRect(origin: .zero, size: Self.size),
                                        styleMask: [.borderless, .nonactivatingPanel],
                                        backing: .buffered, defer: false)
        newPanel.contentView = hosting
        newPanel.isOpaque = false
        newPanel.backgroundColor = .clear
        newPanel.hasShadow = true
        newPanel.level = .floating
        newPanel.isFloatingPanel = true
        newPanel.becomesKeyOnlyIfNeeded = true
        newPanel.hidesOnDeactivate = false
        newPanel.animationBehavior = .none
        newPanel.isReleasedWhenClosed = false
        newPanel.isExcludedFromWindowsMenu = true
        newPanel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .ignoresCycle]
        // Purely decorative: every click belongs to whatever is behind it.
        newPanel.ignoresMouseEvents = true

        panel = newPanel
        hostingView = hosting
    }

    /// Show (or move) the bubble relative to the pet's frame.
    func show(near petFrame: NSRect, on screen: NSScreen?, sentence: String, date: String, time: String) {
        makePanelIfNeeded()
        model.sentence = sentence
        model.dateText = date
        model.timeText = time
        layout(near: petFrame, on: screen)
        panel?.orderFrontRegardless()
    }

    func move(near petFrame: NSRect, on screen: NSScreen?) {
        guard isVisible else { return }
        layout(near: petFrame, on: screen)
    }

    func hide() {
        panel?.orderOut(nil)
    }

    private func layout(near petFrame: NSRect, on screen: NSScreen?) {
        guard let panel else { return }
        let visible = (screen ?? NSScreen.main)?.visibleFrame ?? petFrame
        let size = Self.size
        var x = petFrame.midX - size.width / 2
        var y = petFrame.minY - size.height - 10      // below her by default
        if y < visible.minY + 8 {                     // no room below: go above
            y = petFrame.maxY + 10
        }
        x = min(max(x, visible.minX + 8), visible.maxX - size.width - 8)
        panel.setFrame(NSRect(x: x.rounded(), y: y.rounded(), width: size.width, height: size.height),
                       display: true)
    }
}

private final class HoverBubblePanel: NSPanel {
    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
}

struct HoverBubbleView: View {
    @ObservedObject var model: HoverBubbleModel

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(model.dateText)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)

            Text(model.timeText)
                .font(.system(size: 26, weight: .semibold))
                .monospacedDigit()
                .lineLimit(1)

            Divider()
                .padding(.vertical, 2)

            Text(model.sentence)
                .font(.callout)
                .foregroundStyle(.primary)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
        .frame(width: HoverBubble.size.width, height: HoverBubble.size.height, alignment: .topLeading)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(.regularMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.10), lineWidth: 0.5)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}
