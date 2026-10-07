#!/usr/bin/env swift
// Composes 白饭鱼's 1024×1024 app icon: a full-bleed gradient squircle with her
// (bowl-head skin) standing on it. 100 % canvas fill — no 15 % padding.
// Run: swift scripts/gen_icon.swift  →  icon-src/AppIcon_1024.png
import AppKit
import CoreGraphics

let size = 1024
let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let source = root.appendingPathComponent("Sources/Resources/basin_stand.png")
let outDir = root.appendingPathComponent("icon-src")
try? FileManager.default.createDirectory(at: outDir, withIntermediateDirectories: true)
let output = outDir.appendingPathComponent("AppIcon_1024.png")

guard let art = NSImage(contentsOf: source) else {
    FileHandle.standardError.write("cannot read \(source.path)\n".data(using: .utf8)!)
    exit(1)
}

let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: size, pixelsHigh: size,
                           bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
                           colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
let ctx = NSGraphicsContext.current!.cgContext

let canvas = NSRect(x: 0, y: 0, width: size, height: size)

// ---- Background: full-bleed squircle with a deep-sea gradient ----
let radius: CGFloat = 232
NSBezierPath(roundedRect: canvas, xRadius: radius, yRadius: radius).addClip()
let gradient = NSGradient(colors: [
    NSColor(calibratedRed: 0.35, green: 0.72, blue: 0.98, alpha: 1.0),   // shallow water
    NSColor(calibratedRed: 0.10, green: 0.34, blue: 0.72, alpha: 1.0),   // deep water
])!
gradient.draw(in: canvas, angle: -70)

// A soft light halo behind her so the dark hair doesn't sink into the blue.
ctx.saveGState()
let halo = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                      colors: [NSColor(calibratedWhite: 1.0, alpha: 0.42).cgColor,
                               NSColor(calibratedWhite: 1.0, alpha: 0.0).cgColor] as CFArray,
                      locations: [0, 1])!
ctx.drawRadialGradient(halo, startCenter: CGPoint(x: 512, y: 560), startRadius: 0,
                       endCenter: CGPoint(x: 512, y: 560), endRadius: 430, options: [])
ctx.restoreGState()

// ---- Her, scaled to ~88 % of the canvas so the whole figure reads ----
let artSize = art.size
let target = 880.0
let scale = min(target / artSize.width, target / artSize.height) * 1.0
let w = artSize.width * scale
let h = artSize.height * scale
let rect = NSRect(x: (CGFloat(size) - w) / 2, y: (CGFloat(size) - h) / 2 - 26, width: w, height: h)
art.draw(in: rect, from: .zero, operation: .sourceOver, fraction: 1.0,
         respectFlipped: false, hints: [.interpolation: NSImageInterpolation.high.rawValue])

NSGraphicsContext.restoreGraphicsState()

let png = rep.representation(using: .png, properties: [:])!
try! png.write(to: output)
print("wrote \(output.path)")
