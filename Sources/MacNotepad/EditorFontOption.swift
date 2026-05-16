import AppKit

struct EditorFontOption: Identifiable, Equatable {
    enum FontSource: Equatable {
        case system
        case monospacedSystem
        case named(String)
    }

    let id: String
    let displayName: String
    let source: FontSource

    func font(size: CGFloat) -> NSFont {
        switch source {
        case .system:
            return NSFont.systemFont(ofSize: size)
        case .monospacedSystem:
            return NSFont.monospacedSystemFont(ofSize: size, weight: .regular)
        case .named(let fontName):
            return NSFont(name: fontName, size: size) ?? NSFont.monospacedSystemFont(ofSize: size, weight: .regular)
        }
    }
}

extension EditorFontOption {
    static let all: [EditorFontOption] = [
        EditorFontOption(id: "sf-mono", displayName: "SF Mono", source: .monospacedSystem),
        EditorFontOption(id: "menlo", displayName: "Menlo", source: .named("Menlo-Regular")),
        EditorFontOption(id: "monaco", displayName: "Monaco", source: .named("Monaco")),
        EditorFontOption(id: "courier", displayName: "Courier", source: .named("Courier")),
        EditorFontOption(id: "courier-new", displayName: "Courier New", source: .named("CourierNewPSMT")),
        EditorFontOption(id: "andale-mono", displayName: "Andale Mono", source: .named("AndaleMono")),
        EditorFontOption(id: "system", displayName: "System", source: .system),
        EditorFontOption(id: "helvetica-neue", displayName: "Helvetica Neue", source: .named("HelveticaNeue")),
        EditorFontOption(id: "avenir-next", displayName: "Avenir Next", source: .named("AvenirNext-Regular")),
        EditorFontOption(id: "new-york", displayName: "New York", source: .named("NewYork-Regular"))
    ]

    static let defaultID = "sf-mono"

    static func option(for id: String) -> EditorFontOption {
        all.first { $0.id == id } ?? all[0]
    }
}
