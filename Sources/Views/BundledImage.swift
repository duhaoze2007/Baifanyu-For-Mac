import AppKit

/// Access to the images packaged next to the executable by `build.sh`.
@MainActor
enum BundledImage {
    private static var cache: [String: NSImage] = [:]

    static func image(_ name: String) -> NSImage? {
        if let hit = cache[name] { return hit }
        guard let url = Bundle.module.url(forResource: name, withExtension: "png"),
              let image = NSImage(contentsOf: url) else { return nil }
        cache[name] = image
        return image
    }

    /// Menu bar icon: her face, in colour, sized for the status bar.
    static var menuBarIcon: NSImage? {
        guard let source = image("MenuBarIcon") else { return nil }
        let copy = source.copy() as? NSImage ?? source
        copy.size = NSSize(width: 24, height: 24)
        copy.isTemplate = false
        return copy
    }

    /// The bust used in the settings header.
    static var header: NSImage? { image("header") }
}
