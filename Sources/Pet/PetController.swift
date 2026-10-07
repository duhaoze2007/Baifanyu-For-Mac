import AppKit
import CoreGraphics
import QuartzCore

/// Owns the floating panel, her position, edge snapping, the long-press menu,
/// the squeaks and the idle wandering.
///
/// Port of the Android `PetService` (window management + wander + menu) and the
/// parts of `MainActivity` that drive it. Published properties are the single
/// source of truth for both the menu bar and the settings window.
@MainActor
final class PetController: NSObject, ObservableObject {

    static let shared = PetController()

    // MARK: - Settings (bound by the UI)

    @Published var hoverHeight: Double {
        didSet { AppSettings.hoverHeight = hoverHeight; applyLayout() }
    }
    @Published var perchWidth: Double {
        didSet { AppSettings.perchWidth = perchWidth; applyLayout() }
    }
    @Published var amplitude: Double {
        didSet { AppSettings.amplitude = amplitude; view?.amplitude = CGFloat(amplitude) }
    }
    @Published var soundOn: Bool {
        didSet { AppSettings.soundOn = soundOn; if soundOn { DuckSound.shared.prepare() } }
    }
    @Published var wanderOn: Bool {
        didSet { AppSettings.wanderOn = wanderOn }
    }
    @Published var skinIndex: Int {
        didSet { AppSettings.skinIndex = skinIndex; applySkin() }
    }

    // MARK: - Live state (read-only for the UI)

    @Published private(set) var isRunning: Bool = false
    @Published private(set) var isPerched: Bool = false
    @Published private(set) var perchedOnRight: Bool = false
    @Published private(set) var expression: Int = 0

    // MARK: - Private state

    private var panel: PetPanel?
    private var view: PetView?
    private var frameTimer: Timer?
    private var screenAsleep = false
    private var sessionInactive = false
    private var didInstallMonitors = false

    // Wandering — same numbers as the Android wander loop.
    private var wanderTargetX: CGFloat = -1
    private var wanderX: CGFloat = 0
    private var wanderWaitUntil: CFTimeInterval = 0
    private let wanderMargin: CGFloat = 14
    private let wanderStep: CGFloat = 4

    private override init() {
        hoverHeight = AppSettings.hoverHeight
        perchWidth = AppSettings.perchWidth
        amplitude = AppSettings.amplitude
        soundOn = AppSettings.soundOn
        wanderOn = AppSettings.wanderOn
        skinIndex = AppSettings.skinIndex
        super.init()
    }

    // MARK: - Lifecycle

    /// Called once at launch.
    func start() {
        DuckSound.shared.prepare()
        installObservers()
        installClickThroughMonitors()
        if AppSettings.isRunning { show() }
    }

    func show() {
        guard panel == nil else { return }
        let petView = PetView(frame: .zero)
        petView.artworkSource = { skin, expression in
            PetArtworkStore.shared.sourceImage(skin: skin, expression: expression)
        }
        petView.interactionDelegate = self
        petView.skinIndex = skinIndex
        petView.hoverHeight = CGFloat(hoverHeight)
        petView.perchWidth = CGFloat(perchWidth)
        petView.amplitude = CGFloat(amplitude)
        petView.expression = 0
        expression = 0

        let size = petView.windowSize
        let newPanel = PetPanel(contentRect: NSRect(origin: .zero, size: size),
                                styleMask: [.borderless, .nonactivatingPanel],
                                backing: .buffered, defer: false)
        newPanel.contentView = petView
        newPanel.isOpaque = false
        newPanel.backgroundColor = .clear
        newPanel.hasShadow = false
        newPanel.level = .floating
        newPanel.isFloatingPanel = true
        newPanel.becomesKeyOnlyIfNeeded = true
        newPanel.hidesOnDeactivate = false
        newPanel.isMovableByWindowBackground = false
        newPanel.animationBehavior = .none
        newPanel.isReleasedWhenClosed = false
        newPanel.isExcludedFromWindowsMenu = true
        newPanel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .ignoresCycle]
        newPanel.setFrameOrigin(initialOrigin(for: size))
        newPanel.orderFrontRegardless()

        panel = newPanel
        view = petView
        isRunning = true
        AppSettings.isRunning = true

        if AppSettings.isPerched {
            enterPerch(onRight: AppSettings.perchedEdge == 1, persist: false)
        }
        startFrameTimer()
    }

    func hide() {
        stopFrameTimer()
        panel?.orderOut(nil)
        panel?.contentView = nil
        panel = nil
        view = nil
        isRunning = false
        isPerched = false
        AppSettings.isRunning = false
    }

    func toggle() { isRunning ? hide() : show() }

    // MARK: - Sizes / layout

    /// Re-measures the window for the current mode and keeps her on screen.
    func applyLayout() {
        guard let panel, let view else { return }
        view.hoverHeight = CGFloat(hoverHeight)
        view.perchWidth = CGFloat(perchWidth)
        view.amplitude = CGFloat(amplitude)
        view.skinIndex = skinIndex
        let size = view.windowSize
        var origin = panel.frame.origin
        origin.x += (panel.frame.width - size.width) / 2
        let frame = clamped(origin: origin, size: size)
        panel.setFrame(NSRect(origin: frame, size: size), display: true)
        view.invalidate()
        wanderTargetX = -1
    }

    private func applySkin() {
        guard let view else { return }
        view.skinIndex = skinIndex
        view.setExpression(0)
        PetArtworkStore.shared.purge()
        expression = 0
        applyLayout()
    }

    // MARK: - Screen geometry

    private var screen: NSScreen? {
        panel?.screen ?? NSScreen.main
    }

    private func screenFrame() -> NSRect {
        (screen ?? NSScreen.main)?.frame ?? NSRect(x: 0, y: 0, width: 1440, height: 900)
    }

    private func screenVisibleFrame() -> NSRect {
        (screen ?? NSScreen.main)?.visibleFrame ?? screenFrame()
    }

    /// Keep her mostly on screen: up to 12 % may hang off the top or the bottom,
    /// exactly like the original's clamp(). The menu bar is excluded from the
    /// top limit so she can never hide underneath it.
    private func clamped(origin: NSPoint, size: NSSize) -> NSPoint {
        let full = screenFrame()
        let visible = screenVisibleFrame()
        var x = origin.x
        var y = origin.y
        x = min(max(x, full.minX), max(full.minX, full.maxX - size.width))
        let topLimit = visible.maxY + size.height * 0.12 - size.height
        let bottomLimit = full.minY - size.height * 0.12
        y = min(max(y, bottomLimit), topLimit)
        return NSPoint(x: x, y: y)
    }

    private func initialOrigin(for size: NSSize) -> NSPoint {
        let visible = screenVisibleFrame()
        guard AppSettings.hasSavedPosition else {
            let x = visible.midX - size.width / 2
            let y = visible.maxY - visible.height * 0.42 - size.height
            return clamped(origin: NSPoint(x: x, y: y), size: size)
        }
        return clamped(origin: NSPoint(x: AppSettings.windowX, y: AppSettings.windowY), size: size)
    }

    private func rememberPosition() {
        guard let panel else { return }
        AppSettings.windowX = panel.frame.origin.x
        AppSettings.windowY = panel.frame.origin.y
        AppSettings.hasSavedPosition = true
    }

    // MARK: - Perching on a screen edge

    private func enterPerch(onRight: Bool, persist: Bool) {
        guard let panel, let view else { return }
        view.mode = .perch
        view.mirror = onRight
        isPerched = true
        perchedOnRight = onRight
        let size = view.windowSize
        let full = screenFrame()
        let x = onRight ? full.maxX - size.width : full.minX
        let y = clamped(origin: NSPoint(x: x, y: panel.frame.origin.y), size: size).y
        panel.setFrame(NSRect(x: x, y: y, width: size.width, height: size.height), display: true)
        wanderTargetX = -1
        if persist {
            AppSettings.isPerched = true
            AppSettings.perchedEdge = onRight ? 1 : 0
        }
    }

    private func exitPerch() {
        guard let view else { return }
        view.mode = .hover
        view.mirror = false
        isPerched = false
        AppSettings.isPerched = false
        applyLayout()
    }

    // MARK: - Frame loop & power saving

    private func startFrameTimer() {
        guard frameTimer == nil else { return }
        let timer = Timer(timeInterval: 1.0 / 60.0, target: self, selector: #selector(frameTick), userInfo: nil, repeats: true)
        timer.tolerance = 0.004
        RunLoop.main.add(timer, forMode: .common)
        frameTimer = timer
    }

    private func stopFrameTimer() {
        frameTimer?.invalidate()
        frameTimer = nil
    }

    /// Rendering really stops when nobody can see her — the Android app's third
    /// hard rule about floating windows, applied to macOS.
    private func updateAnimationState() {
        guard isRunning else { stopFrameTimer(); return }
        let occluded = panel.map { !$0.occlusionState.contains(.visible) } ?? true
        if occluded || screenAsleep || sessionInactive {
            stopFrameTimer()
        } else {
            startFrameTimer()
        }
    }

    @objc private func frameTick() {
        guard isRunning, panel != nil, view != nil else { return }
        if !screenAsleep && !sessionInactive {
            updateWander()
            updateClickThrough()   // she may have wandered under a still pointer
            view?.tick(now: CACurrentMediaTime())
        }
    }

    private func installObservers() {
        let center = NotificationCenter.default
        center.addObserver(self, selector: #selector(occlusionChanged),
                           name: NSWindow.didChangeOcclusionStateNotification, object: nil)
        center.addObserver(self, selector: #selector(occlusionChanged),
                           name: NSApplication.didHideNotification, object: nil)
        center.addObserver(self, selector: #selector(occlusionChanged),
                           name: NSApplication.didUnhideNotification, object: nil)

        let workspace = NSWorkspace.shared.notificationCenter
        workspace.addObserver(self, selector: #selector(screensSlept),
                              name: NSWorkspace.screensDidSleepNotification, object: nil)
        workspace.addObserver(self, selector: #selector(screensWoke),
                              name: NSWorkspace.screensDidWakeNotification, object: nil)
        workspace.addObserver(self, selector: #selector(sessionResigned),
                              name: NSWorkspace.sessionDidResignActiveNotification, object: nil)
        workspace.addObserver(self, selector: #selector(sessionBecameActive),
                              name: NSWorkspace.sessionDidBecomeActiveNotification, object: nil)
    }

    @objc private func occlusionChanged() { updateAnimationState() }
    @objc private func screensSlept() { screenAsleep = true; updateAnimationState() }
    @objc private func screensWoke() { screenAsleep = false; updateAnimationState() }
    @objc private func sessionResigned() { sessionInactive = true; updateAnimationState() }
    @objc private func sessionBecameActive() { sessionInactive = false; updateAnimationState() }

    // MARK: - Click-through on transparent pixels

    /// A borderless window swallows clicks over its whole rectangle, including
    /// the transparent margin around her. Watching the pointer and toggling
    /// `ignoresMouseEvents` gives per-pixel click-through, which is what the
    /// original's "never block the app underneath" rule is about.
    private func installClickThroughMonitors() {
        guard !didInstallMonitors else { return }
        didInstallMonitors = true
        NSEvent.addLocalMonitorForEvents(matching: [.mouseMoved, .leftMouseDragged, .rightMouseDragged]) { [weak self] event in
            self?.updateClickThrough()
            return event
        }
        NSEvent.addGlobalMonitorForEvents(matching: [.mouseMoved]) { [weak self] _ in
            self?.updateClickThrough()
        }
    }

    private func updateClickThrough() {
        guard let panel, let view, isRunning else { return }
        if view.isBeingDragged {  // never let go of a drag in progress
            if panel.ignoresMouseEvents { panel.ignoresMouseEvents = false }
            return
        }
        let mouse = NSEvent.mouseLocation
        let insideFrame = panel.frame.contains(mouse)
        var shouldIgnore = true
        if insideFrame {
            let windowPoint = panel.convertPoint(fromScreen: mouse)
            let viewPoint = view.convert(windowPoint, from: nil)
            shouldIgnore = !view.isOpaque(atViewPoint: viewPoint)
        }
        guard shouldIgnore != panel.ignoresMouseEvents else { return }
        panel.ignoresMouseEvents = shouldIgnore
        // She is transparent right under the pointer — give the cursor back to
        // whatever is behind her. Only on the transition, never per frame.
        if shouldIgnore && insideFrame { NSCursor.arrow.set() }
    }

    // MARK: - Idle wandering

    private func updateWander() {
        guard let panel, let view else { return }
        guard wanderOn, isRunning else { view.walking = false; return }
        guard !isPerched, !view.isBeingDragged, view.secondsSinceTouch > 5 else {
            view.walking = false
            return
        }
        let now = CACurrentMediaTime()
        if now < wanderWaitUntil {
            view.walking = false
            return
        }
        let full = screenFrame()
        let width = panel.frame.width
        if wanderTargetX < 0 {
            wanderX = panel.frame.origin.x
            let low = full.minX + wanderMargin
            let high = max(low + 1, full.maxX - width - wanderMargin)
            wanderTargetX = CGFloat.random(in: low...high)
            wanderWaitUntil = now + 0.8
            return
        }
        let d = wanderTargetX - wanderX
        if abs(d) < 3 {
            wanderX = wanderTargetX
            wanderTargetX = -1
            wanderWaitUntil = now + 1.2 + Double.random(in: 0...2.4)
            view.walking = false
            return
        }
        wanderX += (d < 0 ? -1 : 1) * min(wanderStep, abs(d))
        panel.setFrameOrigin(NSPoint(x: wanderX.rounded(), y: panel.frame.origin.y))
        view.walking = true
    }

    // MARK: - Expressions & skin

    func cycleExpression() {
        guard let view else { return }
        let next = view.cycleExpression()
        expression = next
    }

    func selectSkin(_ index: Int) {
        guard index != skinIndex else { return }
        skinIndex = index
    }

    var availableExpressionCount: Int {
        PetArtworkStore.shared.availableExpressionCount(skin: PetSkin.skin(at: skinIndex))
    }

    // MARK: - Long-press / right-click menu

    private func showMenu(for view: PetView) {
        let menu = NSMenu()
        let locale = LocalizationManager.shared

        let skinItem = NSMenuItem(title: "\(locale[.skinMenu]): \(locale[PetSkin.skin(at: skinIndex).nameKey])",
                                  action: #selector(menuNextSkin), keyEquivalent: "")
        skinItem.target = self
        menu.addItem(skinItem)

        let faceItem = NSMenuItem(title: locale[.nextFace], action: #selector(menuNextFace), keyEquivalent: "")
        faceItem.target = self
        menu.addItem(faceItem)

        menu.addItem(.separator())

        let settingsItem = NSMenuItem(title: locale[.settings], action: #selector(menuOpenSettings), keyEquivalent: "")
        settingsItem.target = self
        menu.addItem(settingsItem)

        let hideItem = NSMenuItem(title: locale[.hideHer], action: #selector(menuHide), keyEquivalent: "")
        hideItem.target = self
        menu.addItem(hideItem)

        // NSEvent.mouseLocation is a SCREEN point: convert it to window
        // coordinates first, then into the view's (flipped) space, or the menu
        // pops up somewhere off in the corner of the display.
        guard let window = view.window else { return }
        let screenPoint = NSEvent.mouseLocation
        let windowPoint = window.convertPoint(fromScreen: screenPoint)
        let local = view.convert(windowPoint, from: nil)
        menu.popUp(positioning: nil, at: NSPoint(x: local.x, y: local.y + 6), in: view)
    }

    @objc private func menuNextSkin() { skinIndex = (skinIndex + 1) % PetSkin.skins.count }
    @objc private func menuNextFace() { cycleExpression() }
    @objc private func menuOpenSettings() { SettingsWindowController.shared.open() }
    @objc private func menuHide() { hide() }
}

// MARK: - PetInteractionDelegate

extension PetController: PetInteractionDelegate {
    func petView(_ view: PetView, dragTo windowOrigin: NSPoint) {
        guard let panel else { return }
        if isPerched {
            // Dragging her away from the edge is what brings her back to floating.
            let full = screenFrame()
            if windowOrigin.x > full.minX + full.width * 0.15,
               windowOrigin.x < full.minX + full.width * 0.85 {
                exitPerch()
                panel.setFrameOrigin(windowOrigin)
                return
            }
            panel.setFrameOrigin(NSPoint(x: windowOrigin.x, y: panel.frame.origin.y))
            return
        }
        panel.setFrameOrigin(clamped(origin: windowOrigin, size: panel.frame.size))
        wanderTargetX = -1
    }

    func petViewDidBeginDrag(_ view: PetView) {
        wanderTargetX = -1
    }

    func petViewDidEndDrag(_ view: PetView, at screenPoint: NSPoint) {
        guard let panel else { return }
        rememberPosition()
        guard !isPerched else { return }
        let full = screenFrame()
        // A fixed snap distance would swallow her once she is small, so the
        // threshold is the smaller of 56 pt and 25 % of her width.
        let snap = min(56, panel.frame.width * 0.25)
        if panel.frame.minX <= full.minX + snap {
            enterPerch(onRight: false, persist: true)
        } else if panel.frame.maxX >= full.maxX - snap {
            enterPerch(onRight: true, persist: true)
        } else {
            applyLayout()
        }
    }

    func petViewWasTapped(_ view: PetView) {
        expression = view.expression
        if soundOn { DuckSound.shared.squeak() }
    }

    func petViewNeedsMenu(_ view: PetView) {
        showMenu(for: view)
    }
}

/// Borderless, non-activating, cannot become key — clicking her never steals
/// focus from whatever you are typing in.
private final class PetPanel: NSPanel {
    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
}
