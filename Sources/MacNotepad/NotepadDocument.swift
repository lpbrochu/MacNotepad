import AppKit
import SwiftUI
import UniformTypeIdentifiers

@MainActor
final class NotepadDocument: ObservableObject {
    @Published var text = "" {
        didSet {
            guard !isLoading else { return }
            isDirty = true
            updateCounts()
        }
    }

    @Published var fileURL: URL?
    @Published var isDirty = false
    @Published var wordWrap = true
    @Published var showsStatusBar = true
    @Published var fontSize: CGFloat = 14
    @Published var selectedFontID: String {
        didSet {
            UserDefaults.standard.set(selectedFontID, forKey: Self.selectedFontKey)
        }
    }
    @Published var selection = NSRange(location: 0, length: 0)
    @Published var characterCount = 0
    @Published var showsFindBar = false
    @Published var findText = ""
    @Published var replaceText = ""
    @Published var transientMessage = ""

    private var isLoading = false
    private static let selectedFontKey = "selectedEditorFontID"

    init() {
        selectedFontID = UserDefaults.standard.string(forKey: Self.selectedFontKey) ?? EditorFontOption.defaultID
    }

    var displayTitle: String {
        let base = fileURL?.lastPathComponent ?? "Untitled"
        return isDirty ? "\(base) *" : base
    }

    var statusText: String {
        let position = cursorPosition
        return "Ln \(position.line), Col \(position.column)   \(characterCount) characters   \(fileURL?.path(percentEncoded: false) ?? "Unsaved")"
    }

    var selectedFontOption: EditorFontOption {
        EditorFontOption.option(for: selectedFontID)
    }

    func newDocument() {
        guard confirmSaveIfNeeded() else { return }
        load(text: "", from: nil, dirty: false)
    }

    func openDocument() {
        guard confirmSaveIfNeeded() else { return }

        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.plainText, .text, .utf8PlainText]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false

        guard panel.runModal() == .OK, let url = panel.url else { return }
        openDocument(at: url, shouldConfirmDiscard: false)
    }

    func openDocument(at url: URL, shouldConfirmDiscard: Bool = true) {
        guard !shouldConfirmDiscard || confirmSaveIfNeeded() else { return }

        let didStartAccessing = url.startAccessingSecurityScopedResource()
        defer {
            if didStartAccessing {
                url.stopAccessingSecurityScopedResource()
            }
        }

        var encoding = String.Encoding.utf8
        do {
            let contents = try String(contentsOf: url, usedEncoding: &encoding)
            load(text: contents, from: url, dirty: false)
            transientMessage = "Opened \(url.lastPathComponent)"
        } catch {
            showError("Could not open the file.", informativeText: error.localizedDescription)
        }
    }

    func save() {
        guard let fileURL else {
            saveAs()
            return
        }
        write(to: fileURL)
    }

    func saveAs() {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.plainText]
        panel.canCreateDirectories = true
        panel.nameFieldStringValue = fileURL?.lastPathComponent ?? "Untitled.txt"

        guard panel.runModal() == .OK, let url = panel.url else { return }
        write(to: url)
    }

    func increaseFontSize() {
        fontSize = min(fontSize + 1, 48)
    }

    func decreaseFontSize() {
        fontSize = max(fontSize - 1, 8)
    }

    func resetFontSize() {
        fontSize = 14
    }

    func updateSelection(_ range: NSRange) {
        DispatchQueue.main.async { [weak self] in
            guard let self, self.selection != range else { return }
            self.selection = range
        }
    }

    func findNext() {
        guard !findText.isEmpty else {
            showsFindBar = true
            return
        }
        find(direction: .forward)
    }

    func findPrevious() {
        guard !findText.isEmpty else {
            showsFindBar = true
            return
        }
        find(direction: .backward)
    }

    func replaceCurrentMatch() {
        guard !findText.isEmpty else { return }

        let selectedText = (text as NSString).substring(with: safeSelection)
        if selectedText.compare(findText, options: [.caseInsensitive, .diacriticInsensitive]) == .orderedSame {
            replace(range: safeSelection, with: replaceText)
        } else {
            findNext()
        }
    }

    func replaceAllMatches() {
        guard !findText.isEmpty else { return }
        let updated = text.replacingOccurrences(
            of: findText,
            with: replaceText,
            options: [.caseInsensitive, .diacriticInsensitive]
        )
        guard updated != text else {
            transientMessage = "No matches"
            return
        }

        text = updated
        selection = NSRange(location: 0, length: 0)
        transientMessage = "Replaced all matches"
    }

    private var safeSelection: NSRange {
        let length = (text as NSString).length
        guard selection.location <= length else { return NSRange(location: length, length: 0) }
        return NSRange(location: selection.location, length: min(selection.length, length - selection.location))
    }

    private func load(text: String, from url: URL?, dirty: Bool) {
        isLoading = true
        self.text = text
        fileURL = url
        selection = NSRange(location: 0, length: 0)
        isDirty = dirty
        isLoading = false
        updateCounts()
    }

    private func write(to url: URL) {
        do {
            try text.write(to: url, atomically: true, encoding: .utf8)
            fileURL = url
            isDirty = false
            transientMessage = "Saved \(url.lastPathComponent)"
        } catch {
            showError("Could not save the file.", informativeText: error.localizedDescription)
        }
    }

    func confirmSaveIfNeeded() -> Bool {
        guard isDirty else { return true }

        let alert = NSAlert()
        alert.messageText = "Do you want to save changes to \(fileURL?.lastPathComponent ?? "Untitled")?"
        alert.informativeText = "Your changes will be lost if you don't save them."
        alert.addButton(withTitle: "Save")
        alert.addButton(withTitle: "Don't Save")
        alert.addButton(withTitle: "Cancel")

        switch alert.runModal() {
        case .alertFirstButtonReturn:
            save()
            return !isDirty
        case .alertSecondButtonReturn:
            return true
        default:
            return false
        }
    }

    private enum FindDirection {
        case forward
        case backward
    }

    private func find(direction: FindDirection) {
        let source = text as NSString
        let fullRange = NSRange(location: 0, length: source.length)
        guard fullRange.length > 0 else { return }

        let start: Int
        let searchRange: NSRange

        switch direction {
        case .forward:
            start = min(selection.location + max(selection.length, 1), fullRange.length)
            searchRange = NSRange(location: start, length: fullRange.length - start)
        case .backward:
            start = max(selection.location, 0)
            searchRange = NSRange(location: 0, length: start)
        }

        var options: NSString.CompareOptions = [.caseInsensitive, .diacriticInsensitive]
        if direction == .backward {
            options.insert(.backwards)
        }

        var match = source.range(of: findText, options: options, range: searchRange)
        if match.location == NSNotFound {
            let wrapRange = direction == .forward
                ? NSRange(location: 0, length: fullRange.length)
                : NSRange(location: 0, length: fullRange.length)
            match = source.range(of: findText, options: options, range: wrapRange)
        }

        guard match.location != NSNotFound else {
            transientMessage = "No matches"
            return
        }

        selection = match
        transientMessage = "Match found"
    }

    private func replace(range: NSRange, with replacement: String) {
        let mutable = NSMutableString(string: text)
        mutable.replaceCharacters(in: range, with: replacement)
        text = mutable as String
        selection = NSRange(location: range.location, length: (replacement as NSString).length)
    }

    private func updateCounts() {
        characterCount = text.count
    }

    private var cursorPosition: (line: Int, column: Int) {
        let source = text as NSString
        let cursor = min(selection.location, source.length)
        var currentLine = 1
        var lineStart = 0

        var index = 0
        while index < cursor {
            let character = source.character(at: index)
            if character == 10 {
                currentLine += 1
                lineStart = index + 1
            } else if character == 13 {
                currentLine += 1
                let nextIndex = index + 1
                if nextIndex < cursor, source.character(at: nextIndex) == 10 {
                    index = nextIndex
                }
                lineStart = index + 1
            }
            index += 1
        }

        return (currentLine, cursor - lineStart + 1)
    }

    private func showError(_ message: String, informativeText: String) {
        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.messageText = message
        alert.informativeText = informativeText
        alert.runModal()
    }
}
