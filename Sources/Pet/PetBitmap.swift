import AppKit
import CoreGraphics

/// A CGImage together with the raw ARGB buffer it was rendered into.
///
/// Two reasons for keeping the buffer instead of just the image:
///  1. transparent pixels can be hit-tested cheaply (no NSColor per mouse move);
///  2. the artwork is pre-scaled once per size, so the 30 Hz draw is a plain
///     blit instead of a 5× downscale of a 1 MB PNG.
///
/// Buffer layout (verified on this machine): row 0 is the image's TOP row and
/// the first byte of each pixel is alpha — premultipliedFirst + byteOrder32Big.
final class PetBitmap {
    let image: CGImage
    let pixelWidth: Int
    let pixelHeight: Int

    private let buffer: UnsafeMutablePointer<UInt8>
    private let bytesPerRow: Int

    init?(source: CGImage, pixelWidth: Int, pixelHeight: Int) {
        guard pixelWidth > 0, pixelHeight > 0 else { return nil }
        let bytesPerRow = pixelWidth * 4
        let byteCount = bytesPerRow * pixelHeight
        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: byteCount)
        buffer.initialize(repeating: 0, count: byteCount)

        let bitmapInfo = CGImageAlphaInfo.premultipliedFirst.rawValue | CGBitmapInfo.byteOrder32Big.rawValue
        guard let ctx = CGContext(data: buffer, width: pixelWidth, height: pixelHeight,
                                  bitsPerComponent: 8, bytesPerRow: bytesPerRow,
                                  space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: bitmapInfo) else {
            buffer.deallocate()
            return nil
        }
        ctx.interpolationQuality = .high
        ctx.draw(source, in: CGRect(x: 0, y: 0, width: pixelWidth, height: pixelHeight))
        guard let out = ctx.makeImage() else {
            buffer.deallocate()
            return nil
        }
        self.image = out
        self.pixelWidth = pixelWidth
        self.pixelHeight = pixelHeight
        self.buffer = buffer
        self.bytesPerRow = bytesPerRow
    }

    /// Rotate 90° clockwise, crop to the given fractions of the *original*, then
    /// scale the result to the requested pixel size — all in one pass.
    ///
    /// `crop` is expressed in top-left-origin fractions of the source image
    /// (same convention as Android's `Bitmap.createBitmap` + `Matrix.postRotate(90)`).
    static func perched(source: CGImage, crop: CGRect, pixelWidth: Int, pixelHeight: Int) -> PetBitmap? {
        let sw = CGFloat(source.width), sh = CGFloat(source.height)
        let cropRect = CGRect(x: crop.origin.x * sw,
                              y: crop.origin.y * sh,
                              width: crop.width * sw,
                              height: crop.height * sh).integral
        guard let cropped = source.cropping(to: cropRect) else { return nil }
        let cw = CGFloat(cropped.width), ch = CGFloat(cropped.height)
        guard cw > 0, ch > 0, pixelWidth > 0, pixelHeight > 0 else { return nil }

        let bytesPerRow = pixelWidth * 4
        let byteCount = bytesPerRow * pixelHeight
        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: byteCount)
        buffer.initialize(repeating: 0, count: byteCount)
        let bitmapInfo = CGImageAlphaInfo.premultipliedFirst.rawValue | CGBitmapInfo.byteOrder32Big.rawValue
        guard let ctx = CGContext(data: buffer, width: pixelWidth, height: pixelHeight,
                                  bitsPerComponent: 8, bytesPerRow: bytesPerRow,
                                  space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: bitmapInfo) else {
            buffer.deallocate()
            return nil
        }
        ctx.interpolationQuality = .high
        // Scale last so it applies to the rotated result, then rotate 90° CW.
        ctx.scaleBy(x: CGFloat(pixelWidth) / ch, y: CGFloat(pixelHeight) / cw)
        ctx.translateBy(x: 0, y: cw)
        ctx.rotate(by: -.pi / 2)
        ctx.draw(cropped, in: CGRect(x: 0, y: 0, width: cw, height: ch))
        guard let out = ctx.makeImage() else {
            buffer.deallocate()
            return nil
        }
        let bitmap = PetBitmap(image: out, pixelWidth: pixelWidth, pixelHeight: pixelHeight,
                               buffer: buffer, bytesPerRow: bytesPerRow)
        return bitmap
    }

    private init(image: CGImage, pixelWidth: Int, pixelHeight: Int,
                 buffer: UnsafeMutablePointer<UInt8>, bytesPerRow: Int) {
        self.image = image
        self.pixelWidth = pixelWidth
        self.pixelHeight = pixelHeight
        self.buffer = buffer
        self.bytesPerRow = bytesPerRow
    }

    /// Alpha of the pixel at (x, y) with the origin at the image's top-left,
    /// matching the flipped view coordinate space.
    func alpha(x: Int, y: Int) -> UInt8 {
        guard x >= 0, y >= 0, x < pixelWidth, y < pixelHeight else { return 0 }
        return buffer[y * bytesPerRow + x * 4]
    }

    /// Is there anything visible around (normalised) point `p` in this artwork?
    func isOpaque(atNormalized p: CGPoint, threshold: UInt8 = 26) -> Bool {
        let x = Int(p.x * CGFloat(pixelWidth))
        let y = Int(p.y * CGFloat(pixelHeight))
        return alpha(x: x, y: y) > threshold
    }

    deinit { buffer.deallocate() }
}

/// Loads artwork from the SPM resource bundle and caches the pre-scaled,
/// pre-rotated bitmaps. Cache keys include the pixel size so a slider drag
/// rebuilds at most once per quantised step.
@MainActor
final class PetArtworkStore {
    static let shared = PetArtworkStore()

    private var sources: [String: CGImage] = [:]
    private var cache: [String: PetBitmap] = [:]
    private var misses: Set<String> = []

    private init() {}

    // MARK: - Source artwork

    /// The original, full-resolution standing or expression image of a skin.
    func sourceImage(skin: PetSkin, expression: Int) -> CGImage? {
        let name = skin.resourceName(for: expression)
        if let hit = sources[name] { return hit }
        if misses.contains(name) { return nil }

        guard let url = Bundle.module.url(forResource: name, withExtension: "png"),
              let image = NSImage(contentsOf: url),
              let cg = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            misses.insert(name)
            return nil
        }
        sources[name] = cg
        return cg
    }

    func hasArtwork(skin: PetSkin, expression: Int) -> Bool {
        sourceImage(skin: skin, expression: expression) != nil
    }

    /// How many of the 6 expressions of a skin actually load.
    func availableExpressionCount(skin: PetSkin) -> Int {
        (1...skin.expressionCount).filter { hasArtwork(skin: skin, expression: $0) }.count
    }

    // MARK: - Scaled / rotated artwork

    /// Her whole body, scaled to `pixelHeight`.
    func hoverArtwork(skin: PetSkin, expression: Int, pixelHeight: Int) -> PetBitmap? {
        guard let source = sourceImage(skin: skin, expression: expression) else { return nil }
        let h = max(4, pixelHeight)
        let w = max(4, Int((CGFloat(h) * CGFloat(source.width) / CGFloat(source.height)).rounded()))
        let key = "hover-\(skin.index)-\(expression)-\(h)"
        if let hit = cache[key] { return hit }
        cache[key] = PetBitmap(source: source, pixelWidth: w, pixelHeight: h)
        return cache[key]
    }

    /// Her head only, rotated 90° and scaled so the drawn width is `pixelWidth`.
    func perchArtwork(skin: PetSkin, expression: Int, pixelWidth: Int, aspect: CGFloat) -> PetBitmap? {
        guard let source = sourceImage(skin: skin, expression: expression) else { return nil }
        let w = max(4, pixelWidth)
        let h = max(4, Int((CGFloat(w) * aspect).rounded()))
        let key = "perch-\(skin.index)-\(expression)-\(w)"
        if let hit = cache[key] { return hit }
        let crop = CGRect(x: skin.headX0, y: skin.headY0,
                          width: skin.headX1 - skin.headX0, height: skin.headY1 - skin.headY0)
        cache[key] = PetBitmap.perched(source: source, crop: crop, pixelWidth: w, pixelHeight: h)
        return cache[key]
    }

    /// Drop everything (after a skin switch there is nothing worth keeping).
    func purge() {
        cache.removeAll()
    }
}
