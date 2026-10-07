#!/usr/bin/env swift
// Builds docs/expressions.png — the standing art plus all six expressions of a
// skin, side by side, for the README.
// Run: swift scripts/gen_expressions.swift [basin|maid]
import AppKit
import CoreGraphics

let skin = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "basin"
let faces = ["stand", "face_happy", "face_sad", "face_angry", "face_surprised", "face_shy", "face_confused"]
let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
try? FileManager.default.createDirectory(at: root.appendingPathComponent("docs"), withIntermediateDirectories: true)

let panelH = 420, panelW = 320, gap = 12
let width = panelW * faces.count + gap * (faces.count + 1)
let height = panelH + gap * 2

let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: width, pixelsHigh: height,
                           bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
                           colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
let ctx = NSGraphicsContext.current!.cgContext

// Dark, neutral backdrop so the blue art reads.
NSColor(calibratedRed: 0.09, green: 0.11, blue: 0.16, alpha: 1).setFill()
NSBezierPath(rect: NSRect(x: 0, y: 0, width: width, height: height)).fill()

for (index, name) in faces.enumerated() {
    let path = root.appendingPathComponent("Sources/Resources/\(skin)_\(name).png")
    guard let image = NSImage(contentsOf: path) else {
        FileHandle.standardError.write("missing \(path.path)\n".data(using: .utf8)!)
        continue
    }
    let x = CGFloat(gap + index * (panelW + gap))
    let panel = NSRect(x: x, y: CGFloat(gap), width: CGFloat(panelW), height: CGFloat(panelH))
    NSColor(calibratedWhite: 1.0, alpha: 0.05).setFill()
    NSBezierPath(roundedRect: panel, xRadius: 18, yRadius: 18).fill()

    let art = image.size
    let scale = min((CGFloat(panelW) - 40) / art.width, (CGFloat(panelH) - 40) / art.height)
    let w = art.width * scale, h = art.height * scale
    let rect = NSRect(x: x + (CGFloat(panelW) - w) / 2, y: CGFloat(gap) + (CGFloat(panelH) - h) / 2, width: w, height: h)
    image.draw(in: rect, from: .zero, operation: .sourceOver, fraction: 1.0,
               respectFlipped: false, hints: [.interpolation: NSImageInterpolation.high.rawValue])

    let label = index == 0 ? "stand" : String(name.dropFirst("face_".count))
    let attributes: [NSAttributedString.Key: Any] = [
        .font: NSFont.systemFont(ofSize: 22, weight: .medium),
        .foregroundColor: NSColor(calibratedWhite: 1.0, alpha: 0.65),
    ]
    let text = NSAttributedString(string: label, attributes: attributes)
    let size = text.size()
    text.draw(at: NSPoint(x: x + (CGFloat(panelW) - size.width) / 2, y: CGFloat(gap) + 12))
}

NSGraphicsContext.restoreGraphicsState()
let out = root.appendingPathComponent("docs/expressions.png")
try! rep.representation(using: .png, properties: [:])!.write(to: out)
print("wrote \(out.path) (\(width)x\(height))")
