import Foundation

/// Everything the pet and the UI read/write. UserDefaults-backed so it stays
/// readable from the window controller, the drawing view and the SwiftUI views.
///
/// Key names mirror the Android original (`whalepet` SharedPreferences) so the
/// numbers mean the same thing: dp == pt, defaults 240 / 96 / 0.75.
enum AppSettings {
    private static var d: UserDefaults { .standard }

    enum Key {
        static let hoverHeight = "whalepet.hover_height_dp"
        static let perchWidth  = "whalepet.perch_width_dp"
        static let amplitude   = "whalepet.amp_scale"
        static let soundOn     = "whalepet.sound_on"
        static let wanderOn    = "whalepet.wander_on"
        static let randomFace  = "whalepet.random_face"
        static let skinIndex   = "whalepet.skin_index"
        static let running     = "whalepet.running"
        static let perched     = "whalepet.perched"
        static let perchedEdge = "whalepet.edge"
        static let windowX     = "whalepet.window_x"
        static let windowY     = "whalepet.window_y"
        static let hasPosition = "whalepet.has_position"
        static let language    = "whalepet.language"
    }

    // Ranges & defaults — identical to the Android app's sliders.
    static let minHoverHeight = 120.0, maxHoverHeight = 480.0, defaultHoverHeight = 240.0
    static let minPerchWidth  = 56.0,  maxPerchWidth  = 160.0, defaultPerchWidth  = 96.0
    static let minAmplitude   = 0.30,  maxAmplitude   = 1.50,  defaultAmplitude   = 0.75

    static var hoverHeight: Double {
        get { clampD(d.object(forKey: Key.hoverHeight) as? Double ?? defaultHoverHeight, minHoverHeight, maxHoverHeight) }
        set { d.set(newValue, forKey: Key.hoverHeight) }
    }

    static var perchWidth: Double {
        get { clampD(d.object(forKey: Key.perchWidth) as? Double ?? defaultPerchWidth, minPerchWidth, maxPerchWidth) }
        set { d.set(newValue, forKey: Key.perchWidth) }
    }

    static var amplitude: Double {
        get { clampD(d.object(forKey: Key.amplitude) as? Double ?? defaultAmplitude, minAmplitude, maxAmplitude) }
        set { d.set(newValue, forKey: Key.amplitude) }
    }

    static var soundOn: Bool {
        get { d.object(forKey: Key.soundOn) as? Bool ?? true }
        set { d.set(newValue, forKey: Key.soundOn) }
    }

    static var wanderOn: Bool {
        get { d.object(forKey: Key.wanderOn) as? Bool ?? true }
        set { d.set(newValue, forKey: Key.wanderOn) }
    }

    /// She picks a new expression by herself now and then.
    static var randomFace: Bool {
        get { d.object(forKey: Key.randomFace) as? Bool ?? true }
        set { d.set(newValue, forKey: Key.randomFace) }
    }

    static var skinIndex: Int {
        get { min(max(d.object(forKey: Key.skinIndex) as? Int ?? 0, 0), PetSkin.skins.count - 1) }
        set { d.set(newValue, forKey: Key.skinIndex) }
    }

    /// She is on screen (vs. called off).
    static var isRunning: Bool {
        get { d.object(forKey: Key.running) as? Bool ?? true }
        set { d.set(newValue, forKey: Key.running) }
    }

    static var isPerched: Bool {
        get { d.bool(forKey: Key.perched) }
        set { d.set(newValue, forKey: Key.perched) }
    }

    /// 1 = right edge, 0 = left edge.
    static var perchedEdge: Int {
        get { d.integer(forKey: Key.perchedEdge) }
        set { d.set(newValue, forKey: Key.perchedEdge) }
    }

    static var hasSavedPosition: Bool {
        get { d.bool(forKey: Key.hasPosition) }
        set { d.set(newValue, forKey: Key.hasPosition) }
    }

    static var windowX: Double {
        get { d.double(forKey: Key.windowX) }
        set { d.set(newValue, forKey: Key.windowX) }
    }

    static var windowY: Double {
        get { d.double(forKey: Key.windowY) }
        set { d.set(newValue, forKey: Key.windowY) }
    }

    static var languageOverride: String? {
        get { d.string(forKey: Key.language) }
        set {
            if let newValue { d.set(newValue, forKey: Key.language) }
            else { d.removeObject(forKey: Key.language) }
        }
    }

    private static func clampD(_ v: Double, _ lo: Double, _ hi: Double) -> Double {
        Swift.min(Swift.max(v, lo), hi)
    }
}
