#!/usr/bin/env swift
// Renders 白饭鱼's menu bar icon in FULL COLOUR: her head (bowl-head skin),
// tightly cropped, antialiased, 44 px tall (= 22 pt @2x).
// Template silhouettes of this artwork turn into a blob — colour is what makes
// her readable at menu-bar size.
// Run: swift scripts/gen_menubar_icon.swift
import AppKit
import CoreGraphics

let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let source = root.appendingPathComponent("Sources/Resources/basin_stand.png")
let output = root.appendingPathComponent("Sources/Resources/MenuBarIcon.png")

guard let image = NSImage(contentsOf: source),
      let cg = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
    FileHandle.standardError.write("cannot read \(source.path)\n".data(using: .utf8)!)
    exit(1)
}

let sw = CGFloat(cg.width), sh = CGFloat(cg.height)
// Head crop — the same ratios the app uses for the perched pose, but with a bit
// more of the shoulders so the cut doesn't look accidental.
let crop = CGRect(x: 0.020 * sw, y: 0.010 * sh,
                  width: (0.985 - 0.020) * sw, height: (0.640 - 0.010) * sh).integral
guard let head = cg.cropping(to: crop) else { exit(1) }

// Tight alpha box so her face fills the icon.
let probeW = 200, probeH = 160
let probeBytes = probeW * 4
let probe = UnsafeMutablePointer<UInt8>.allocate(capacity: probeBytes * probeH)
probe.initialize(repeating: 0, count: probeBytes * probeH)
let probeCtx = CGContext(data: probe, width: probeW, height: probeH, bitsPerComponent: 8, bytesPerRow: probeBytes,
                         space: CGColorSpaceCreateDeviceRGB(),
                         bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue | CGBitmapInfo.byteOrder32Big.rawValue)!
probeCtx.interpolationQuality = .high
probeCtx.draw(head, in: CGRect(x: 0, y: 0, width: probeW, height: probeH))
var minX = probeW, maxX = -1, minY = probeH, maxY = -1
for row in 0..<probeH {
    for col in 0..<probeW where probe[row * probeBytes + col * 4] > 16 {
        minX = min(minX, col); maxX = max(maxX, col)
        minY = min(minY, row); maxY = max(maxY, row)
    }
}
probe.deallocate()
let scaleX = CGFloat(head.width) / CGFloat(probeW), scaleY = CGFloat(head.height) / CGFloat(probeH)
let box = CGRect(x: CGFloat(minX) * scaleX, y: CGFloat(minY) * scaleY,
                 width: CGFloat(maxX - minX + 1) * scaleX, height: CGFloat(maxY - minY + 1) * scaleY).integral
guard let face = head.cropping(to: box) else { exit(1) }

let side = 48
let fit = 44.0
let figScale = min(fit / Double(face.width), fit / Double(face.height))
let drawW = Double(face.width) * figScale
let drawH = Double(face.height) * figScale

let bytesPerRow = side * 4
let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bytesPerRow * side)
buffer.initialize(repeating: 0, count: bytesPerRow * side)
let ctx = CGContext(data: buffer, width: side, height: side, bitsPerComponent: 8, bytesPerRow: bytesPerRow,
                    space: CGColorSpaceCreateDeviceRGB(),
                    bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue | CGBitmapInfo.byteOrder32Big.rawValue)!
ctx.interpolationQuality = .high
ctx.draw(face, in: CGRect(x: (Double(side) - drawW) / 2, y: (Double(side) - drawH) / 2, width: drawW, height: drawH))

guard let out = ctx.makeImage() else { exit(1) }
let rep = NSBitmapImageRep(cgImage: out)
rep.size = NSSize(width: side / 2, height: side / 2)
try! rep.representation(using: .png, properties: [:])!.write(to: output)
print("wrote \(output.path) (\(side)×\(side) px = \(side / 2) pt)")
