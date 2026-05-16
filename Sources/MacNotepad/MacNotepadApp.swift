import SwiftUI
import AppKit

@main
struct MacNotepadApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var document = NotepadDocument()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(document)
                .frame(minWidth: 520, minHeight: 360)
                .onAppear {
                    NSWindow.allowsAutomaticWindowTabbing = false
                    appDelegate.openURLHandler = { url in
                        document.openDocument(at: url)
                    }
                    appDelegate.openPendingURLs()
                }
                .onOpenURL { url in
                    document.openDocument(at: url)
                }
        }
        .commands {
            NotepadCommands(document: document)
            CommandGroup(replacing: .appSettings) {
                Button("Settings...") {
                    NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
                }
                .keyboardShortcut(",", modifiers: [.command])
            }
        }

        Settings {
            SettingsView()
                .environmentObject(document)
        }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    var openURLHandler: ((URL) -> Void)?
    private var pendingURLs: [URL] = []

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }

    func application(_ application: NSApplication, open urls: [URL]) {
        guard let openURLHandler else {
            pendingURLs.append(contentsOf: urls)
            return
        }

        urls.forEach(openURLHandler)
    }

    func openPendingURLs() {
        guard let openURLHandler, !pendingURLs.isEmpty else { return }
        let urls = pendingURLs
        pendingURLs.removeAll()
        urls.forEach(openURLHandler)
    }
}

struct NotepadCommands: Commands {
    @ObservedObject var document: NotepadDocument

    var body: some Commands {
        CommandGroup(replacing: .newItem) {
            Button("New") { document.newDocument() }
                .keyboardShortcut("n")
            Button("Open...") { document.openDocument() }
                .keyboardShortcut("o")
            Divider()
            Button("Save") { document.save() }
                .keyboardShortcut("s")
            Button("Save As...") { document.saveAs() }
                .keyboardShortcut("s", modifiers: [.command, .shift])
        }

        CommandMenu("Format") {
            Toggle("Word Wrap", isOn: $document.wordWrap)
            Divider()
            Button("Bigger Font") { document.increaseFontSize() }
                .keyboardShortcut("+", modifiers: [.command])
            Button("Smaller Font") { document.decreaseFontSize() }
                .keyboardShortcut("-", modifiers: [.command])
            Button("Reset Font Size") { document.resetFontSize() }
                .keyboardShortcut("0", modifiers: [.command])
        }

        CommandMenu("View") {
            Toggle("Status Bar", isOn: $document.showsStatusBar)
        }

        CommandMenu("Search") {
            Button("Find...") { document.showsFindBar = true }
                .keyboardShortcut("f")
            Button("Find Next") { document.findNext() }
                .keyboardShortcut("g")
            Button("Find Previous") { document.findPrevious() }
                .keyboardShortcut("g", modifiers: [.command, .shift])
            Divider()
            Button("Replace") { document.replaceCurrentMatch() }
                .keyboardShortcut("h", modifiers: [.command])
            Button("Replace All") { document.replaceAllMatches() }
        }
    }
}
