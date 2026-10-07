import Foundation
import CoreGraphics

/// One skin = a standing image + 6 expressions, plus how to crop her head when
/// she perches on a screen edge.
///
/// The crop ratios are measured on the *original* artwork and are different per
/// skin: the bowl on the bowl-head skin is much wider than the maid's head, so
/// reusing one set of ratios would slice off the edge of the bowl.
struct PetSkin {
    let index: Int
    let nameKey: L10nKey
    /// Resource name prefix (`basin` / `maid`).
    let prefix: String
    /// Head crop in fractions of the original image (top-left origin).
    let headX0: CGFloat
    let headX1: CGFloat
    let headY0: CGFloat
    let headY1: CGFloat

    /// Expression order, identical to the Android app's `SKINS[].faces`.
    static let faceOrder = ["happy", "sad", "angry", "surprised", "shy", "confused"]

    var standResource: String { "\(prefix)_stand" }
    var faceResources: [String] { Self.faceOrder.map { "\(prefix)_face_\($0)" } }

    /// Expression index 0 means "no expression" (the plain standing art);
    /// 1...6 index into `faceResources`.
    var expressionCount: Int { faceResources.count }

    static let skins: [PetSkin] = [
        PetSkin(index: 0, nameKey: .skinBasin, prefix: "basin",
                headX0: 0.020, headX1: 0.985, headY0: 0.015, headY1: 0.560),
        PetSkin(index: 1, nameKey: .skinMaid, prefix: "maid",
                headX0: 35.0 / 1191.0, headX1: 985.0 / 1191.0,
                headY0: 30.0 / 1514.0, headY1: 800.0 / 1514.0),
    ]

    static func skin(at index: Int) -> PetSkin {
        skins[min(max(index, 0), skins.count - 1)]
    }

    func resourceName(for expression: Int) -> String {
        expression <= 0 ? standResource : faceResources[expression - 1]
    }
}
