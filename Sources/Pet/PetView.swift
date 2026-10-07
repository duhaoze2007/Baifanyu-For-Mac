import AppKit
import CoreGraphics
import QuartzCore

@MainActor
protocol PetInteractionDelegate: AnyObject {
    /// Screen-coordinate position the window should move to.
    func petView(_ view: PetView, dragTo windowOrigin: NSPoint)
    func petViewDidBeginDrag(_ view: PetView)
    func petViewDidEndDrag(_ view: PetView, at screenPoint: NSPoint)
    func petViewWasTapped(_ view: PetView)
    func petViewNeedsMenu(_ view: PetView)
}

/// Draws her, animates her, and turns mouse events into drags / taps / long presses.
///
/// The geometry is a direct port of the Android `PetView`: the same floating
/// bob, the same breathing squash, the same drag tilt, the same head-only crop
/// while perched. Points take the place of dp.
final class PetView: NSView {

    enum Mode { case hover, perch }

    weak var interactionDelegate: PetInteractionDelegate?
    var artworkSource: ((PetSkin, Int) -> CGImage?)?

    // MARK: - Configuration (set by the controller)

    var skinIndex = 0 { didSet { if oldValue != skinIndex { invalidate() } } }
    var expression = 0 { didSet { if oldValue != expression { invalidate() } } }
    var mode: Mode = .hover { didSet { if oldValue != mode { invalidate() } } }
    var mirror = false
    var walking = false { didSet { if oldValue != walking { invalidate() } } }

    /// Sizes in points, matching the Android sliders (dp).
    var hoverHeight: CGFloat = 240 { didSet { invalidate() } }
    var perchWidth: CGFloat = 96 { didSet { invalidate() } }
    var amplitude: CGFloat = 0.75 { didSet { invalidate() } }

    /// How long a frame lasts, in seconds (30 fps floating / 20 fps perched).
    var frameInterval: CFTimeInterval { mode == .perch ? 1.0 / 20.0 : 1.0 / 30.0 }
    // MARK: - State

    private var startTime: CFTimeInterval = 0
    private var lastFrameTime: CFTimeInterval = 0
    private var tapTime: CFTimeInterval = 0
    private var dragTilt: CGFloat = 0
    private var pDy: CGFloat = 0
    private var pSx: CGFloat = 1
    private var pSy: CGFloat = 1

    private(set) var dragging = false
    private var mouseDownScreenPoint: NSPoint = .zero
    private var windowOriginAtMouseDown: NSPoint = .zero
    private var lastScreenPoint: NSPoint = .zero
    private var longPressTimer: Timer?
    private var lastTouchTime: CFTimeInterval = CACurrentMediaTime()

    private var trackingArea: NSTrackingArea?

    override var isFlipped: Bool { true }
    override var acceptsFirstResponder: Bool { false }
    override var mouseDownCanMoveWindow: Bool { false }

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
        layer?.isOpaque = false
        layer?.backgroundColor = .clear
    }

    required init?(coder: NSCoder) { fatalError("not used") }

    // MARK: - Geometry

    var skin: PetSkin { PetSkin.skin(at: skinIndex) }

    private var sourceSize: CGSize {
        guard let cg = artworkSource?(skin, 0) else { return CGSize(width: 943, height: 1200) }
        return CGSize(width: cg.width, height: cg.height)
    }

    var sourceAspect: CGFloat {
        let size = sourceSize
        guard size.height > 0 else { return 0.786 }
        return size.width / size.height
    }

    /// drawnHeadHeight / drawnHeadWidth for the perched pose.
    var perchHeadAspect: CGFloat {
        let s = skin, size = sourceSize
        let cropW = (s.headX1 - s.headX0) * size.width
        let cropH = (s.headY1 - s.headY0) * size.height
        guard cropW > 0 else { return 1.23 }
        return cropH / cropW
    }

    var hoverWindowSize: NSSize {
        NSSize(width: (hoverHeight * sourceAspect).rounded(), height: (hoverHeight * 1.16).rounded())
    }

    var perchWindowSize: NSSize {
        let drawnWidth = perchWidth
        let drawnHeight = perchWidth * perchHeadAspect
        return NSSize(width: (drawnWidth * 1.10).rounded(), height: (drawnHeight * 1.16).rounded())
    }

    var windowSize: NSSize { mode == .perch ? perchWindowSize : hoverWindowSize }

    // MARK: - Expressions

    func setExpression(_ value: Int) {
        guard value != expression else { return }
        expression = value
        invalidate()
    }

    /// Clicking her cycles 0 → 1 → … → 6 → 0, skipping expressions whose art is missing.
    @discardableResult
    func cycleExpression() -> Int {
        let skin = self.skin
        let total = skin.expressionCount
        for step in 1...total {
            let candidate = (expression + step) % (total + 1)
            if candidate == 0 || artworkSource?(skin, candidate) != nil {
                setExpression(candidate)
                return candidate
            }
        }
        return expression
    }

    func advancedExpression(from value: Int) -> Int {
        let skin = self.skin
        let total = skin.expressionCount
        for step in 1...total {
            let candidate = (value + step) % (total + 1)
            if candidate == 0 || artworkSource?(skin, candidate) != nil { return candidate }
        }
        return value
    }

    func pokeFeedback() {
        tapTime = CACurrentMediaTime()
        invalidate()
    }

    // MARK: - Frame loop

    /// Called by the controller's timer. Returns true when a redraw happened.
    @discardableResult
    func tick(now: CFTimeInterval) -> Bool {
        if startTime == 0 { startTime = now }
        if now - lastFrameTime >= frameInterval {
            lastFrameTime = now
            invalidate()
            return true
        }
        return false
    }

    func invalidate() {
        needsDisplay = true
    }

    // MARK: - Drawing

    override func draw(_ dirtyRect: NSRect) {
        guard let ctx = NSGraphicsContext.current?.cgContext else { return }
        let now = CACurrentMediaTime()
        if startTime == 0 { startTime = now; lastFrameTime = now }
        let t = CGFloat(now - startTime)
        updateDynamics(t: t, now: now)

        switch mode {
        case .hover: drawHover(ctx, t: t)
        case .perch: drawPerch(ctx, t: t)
        }
    }

    /// Floating bob + breathing squash, drag tilt, walk wobble, poke squash.
    private func updateDynamics(t: CGFloat, now: CFTimeInterval) {
        let tau = 2 * CGFloat.pi
        pDy = 0.022 * amplitude * sin(tau * t / 2.4)
        pSx = 1
        pSy = 1 + 0.014 * amplitude * sin(tau * 2 * t / 2.4)

        if dragging {
            pSx += 0.05 * abs(dragTilt) / 9
            pSy -= 0.02 * abs(dragTilt) / 9
        }
        if walking {
            // Walking = left/right sway + up/down bounce. Pure translation looks
            // like a sliding sticker, not like walking.
            let wk = tau * t * 1.9
            pDy += 0.016 * amplitude * abs(sin(wk))
            pSy *= 1 + 0.018 * amplitude * sin(wk * 2)
            dragTilt = 5.5 * sin(wk)
        } else if !dragging {
            dragTilt = 0
        }
        if tapTime != 0 {
            let k = CGFloat(now - tapTime) / 0.30
            if k >= 1 { tapTime = 0 } else { pSy *= 1 - 0.10 * sin(.pi * k) }
        }
    }

    private func artwork(scale: CGFloat) -> PetBitmap? {
        let store = PetArtworkStore.shared
        switch mode {
        case .hover:
            let pixels = Int((hoverHeight * scale).rounded())
            return store.hoverArtwork(skin: skin, expression: expression, pixelHeight: pixels)
        case .perch:
            let pixels = Int((perchWidth * scale).rounded())
            return store.perchArtwork(skin: skin, expression: expression,
                                      pixelWidth: pixels, aspect: perchHeadAspect)
        }
    }

    /// The on-screen rectangle the artwork is drawn into (flipped view coords).
    func destinationRect() -> CGRect {
        let w = bounds.width, h = bounds.height
        if mode == .hover {
            let artH = hoverHeight
            let artW = artH * sourceAspect
            let cx = w / 2
            let bottom = h - artH * 0.08 + pDy * artH
            let top = bottom - artH * pSy
            let halfW = artW * pSx / 2
            return CGRect(x: cx - halfW, y: top, width: halfW * 2, height: bottom - top)
        } else {
            let artW = perchWidth
            let artH = perchWidth * perchHeadAspect
            let peek = artW * 0.02 * (1 + sin(2 * .pi * CGFloat(animationTime) / 2.4 - 1.2))
            let hh = artH * pSy
            let top = (h - hh) / 2 + pDy * artH
            return CGRect(x: peek, y: top, width: artW, height: hh)
        }
    }

    private var animationTime: CFTimeInterval {
        startTime == 0 ? 0 : CACurrentMediaTime() - startTime
    }

    private func drawHover(_ ctx: CGContext, t: CGFloat) {
        let scale = window?.backingScaleFactor ?? 2
        guard let bitmap = artwork(scale: scale) else { return }
        let dst = destinationRect()
        let cx = bounds.width / 2
        let pivotY = bounds.height - hoverHeight * 0.10

        ctx.saveGState()
        if dragging && dragTilt != 0 {
            ctx.translateBy(x: cx, y: pivotY)
            ctx.rotate(by: dragTilt * .pi / 180)
            ctx.translateBy(x: -cx, y: -pivotY)
        }
        drawUpright(bitmap.image, in: dst, ctx: ctx)
        ctx.restoreGState()
    }

    private func drawPerch(_ ctx: CGContext, t: CGFloat) {
        let scale = window?.backingScaleFactor ?? 2
        guard let bitmap = artwork(scale: scale) else { return }
        let dst = destinationRect()
        let cx = bounds.width / 2

        ctx.saveGState()
        if mirror {
            ctx.translateBy(x: cx * 2, y: 0)
            ctx.scaleBy(x: -1, y: 1)
        }
        drawUpright(bitmap.image, in: dst, ctx: ctx)
        ctx.restoreGState()
    }

    /// The view is flipped (y grows downwards) while CGContext.draw() expects a
    /// y-up space, so flip the rect back before blitting or she renders upside down.
    private func drawUpright(_ image: CGImage, in rect: CGRect, ctx: CGContext) {
        ctx.saveGState()
        ctx.translateBy(x: 0, y: rect.minY + rect.maxY)
        ctx.scaleBy(x: 1, y: -1)
        ctx.interpolationQuality = .high
        ctx.draw(image, in: rect)
        ctx.restoreGState()
    }

    // MARK: - Transparent-area hit testing

    /// Click-through support: a point over a fully transparent pixel does not
    /// belong to her (the controller uses this to toggle `ignoresMouseEvents`).
    func isOpaque(atViewPoint point: NSPoint) -> Bool {
        guard bounds.contains(point) else { return false }
        let scale = window?.backingScaleFactor ?? 2
        guard let bitmap = artwork(scale: scale) else { return false }
        let dst = destinationRect()
        guard dst.width > 1, dst.height > 1 else { return false }
        let normalized = CGPoint(x: (point.x - dst.minX) / dst.width,
                                 y: (point.y - dst.minY) / dst.height)
        guard normalized.x >= 0, normalized.x <= 1, normalized.y >= 0, normalized.y <= 1 else { return false }
        return bitmap.isOpaque(atNormalized: normalized)
    }

    /// Points over fully transparent pixels are not hers: `nil` here keeps the
    /// window from swallowing clicks that belong to the app behind her.
    override func hitTest(_ point: NSPoint) -> NSView? {
        guard let superview else { return nil }
        let local = convert(point, from: superview)
        guard bounds.contains(local), isOpaque(atViewPoint: local) else { return nil }
        return self
    }

    // MARK: - Mouse

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        if let trackingArea { removeTrackingArea(trackingArea) }
        let area = NSTrackingArea(rect: bounds,
                                  options: [.mouseEnteredAndExited, .cursorUpdate, .activeAlways],
                                  owner: self, userInfo: nil)
        addTrackingArea(area)
        trackingArea = area
    }

    override func cursorUpdate(with event: NSEvent) {
        (dragging ? NSCursor.closedHand : NSCursor.openHand).set()
    }

    override func mouseEntered(with event: NSEvent) {
        NSCursor.openHand.set()
    }

    override func mouseExited(with event: NSEvent) {
        if !dragging { NSCursor.arrow.set() }
    }

    override func mouseDown(with event: NSEvent) {
        if event.modifierFlags.contains(.control) {
            interactionDelegate?.petViewNeedsMenu(self)
            return
        }
        lastTouchTime = CACurrentMediaTime()
        mouseDownScreenPoint = NSEvent.mouseLocation
        lastScreenPoint = mouseDownScreenPoint
        windowOriginAtMouseDown = window?.frame.origin ?? .zero
        dragging = false
        dragTilt = 0
        NSCursor.closedHand.set()
        longPressTimer?.invalidate()
        longPressTimer = Timer.scheduledTimer(withTimeInterval: 0.8, repeats: false) { [weak self] _ in
            // The block is @Sendable but always fires on the main run loop.
            MainActor.assumeIsolated {
                guard let self, !self.dragging else { return }
                self.interactionDelegate?.petViewNeedsMenu(self)
            }
        }
        invalidate()
    }

    override func mouseDragged(with event: NSEvent) {
        let point = NSEvent.mouseLocation
        let distance = hypot(point.x - mouseDownScreenPoint.x, point.y - mouseDownScreenPoint.y)
        if distance > 3 { longPressTimer?.invalidate() }
        if !dragging && distance > 3 {
            dragging = true
            interactionDelegate?.petViewDidBeginDrag(self)
        }
        guard dragging else { return }
        lastTouchTime = CACurrentMediaTime()
        dragTilt = max(-9, min(9, dragTilt + (point.x - lastScreenPoint.x) * 0.35))
        dragTilt *= 0.85
        lastScreenPoint = point
        let origin = NSPoint(x: windowOriginAtMouseDown.x + (point.x - mouseDownScreenPoint.x),
                             y: windowOriginAtMouseDown.y + (point.y - mouseDownScreenPoint.y))
        interactionDelegate?.petView(self, dragTo: origin)
        invalidate()
    }

    override func mouseUp(with event: NSEvent) {
        longPressTimer?.invalidate()
        longPressTimer = nil
        if dragging {
            dragging = false
            dragTilt = 0
            interactionDelegate?.petViewDidEndDrag(self, at: NSEvent.mouseLocation)
        } else {
            cycleExpression()
            pokeFeedback()
            interactionDelegate?.petViewWasTapped(self)
        }
        if !bounds.contains(convert(event.locationInWindow, from: nil)) {
            NSCursor.arrow.set()
        } else {
            NSCursor.openHand.set()
        }
        invalidate()
    }

    override func rightMouseDown(with event: NSEvent) {
        longPressTimer?.invalidate()
        interactionDelegate?.petViewNeedsMenu(self)
    }

    /// Seconds since she was last touched — she keeps still for a moment after.
    var secondsSinceTouch: CFTimeInterval { CACurrentMediaTime() - lastTouchTime }

    var isBeingDragged: Bool { dragging }
}
