import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var document: NotepadDocument
    @FocusState private var editorFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            PlainTextEditor(
                text: $document.text,
                selection: $document.selection,
                wordWrap: $document.wordWrap,
                fontSize: $document.fontSize,
                selectedFontID: $document.selectedFontID,
                onSelectionChange: document.updateSelection
            )
            .focused($editorFocused)

            if document.showsFindBar {
                FindBar()
                    .environmentObject(document)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            if document.showsStatusBar {
                HStack(spacing: 12) {
                    Text(document.statusText)
                    Spacer()
                    if !document.transientMessage.isEmpty {
                        Text(document.transientMessage)
                            .foregroundStyle(.secondary)
                    }
                }
                .font(.system(size: 12))
                .lineLimit(1)
                .padding(.horizontal, 10)
                .frame(height: 24)
                .background(Color(nsColor: .windowBackgroundColor))
                .overlay(alignment: .top) {
                    Divider()
                }
            }
        }
        .navigationTitle(document.displayTitle)
        .background {
            WindowCloseHandler {
                document.confirmSaveIfNeeded()
            }
        }
        .onAppear {
            editorFocused = true
        }
        .animation(.snappy(duration: 0.18), value: document.showsFindBar)
    }
}

private struct WindowCloseHandler: NSViewRepresentable {
    let shouldClose: () -> Bool

    func makeCoordinator() -> Coordinator {
        Coordinator(shouldClose: shouldClose)
    }

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            context.coordinator.attach(to: view.window)
        }
        return view
    }

    func updateNSView(_ view: NSView, context: Context) {
        context.coordinator.shouldClose = shouldClose
        DispatchQueue.main.async {
            context.coordinator.attach(to: view.window)
        }
    }

    @MainActor
    final class Coordinator: NSObject, NSWindowDelegate {
        var shouldClose: () -> Bool
        private weak var window: NSWindow?

        init(shouldClose: @escaping () -> Bool) {
            self.shouldClose = shouldClose
        }

        func attach(to window: NSWindow?) {
            guard self.window !== window else { return }
            self.window?.delegate = nil
            self.window = window
            window?.delegate = self
        }

        func windowShouldClose(_ sender: NSWindow) -> Bool {
            shouldClose()
        }
    }
}

private struct FindBar: View {
    @EnvironmentObject private var document: NotepadDocument
    @FocusState private var findFocused: Bool

    var body: some View {
        HStack(spacing: 8) {
            TextField("Find", text: $document.findText)
                .textFieldStyle(.roundedBorder)
                .frame(width: 180)
                .focused($findFocused)
                .onSubmit(document.findNext)

            Button("Next", action: document.findNext)
            Button("Previous", action: document.findPrevious)

            Divider()
                .frame(height: 20)

            TextField("Replace", text: $document.replaceText)
                .textFieldStyle(.roundedBorder)
                .frame(width: 180)
                .onSubmit(document.replaceCurrentMatch)

            Button("Replace", action: document.replaceCurrentMatch)
            Button("All", action: document.replaceAllMatches)

            Spacer()

            Button {
                document.showsFindBar = false
            } label: {
                Image(systemName: "xmark")
            }
            .buttonStyle(.borderless)
            .help("Close")
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(Color(nsColor: .windowBackgroundColor))
        .overlay(alignment: .top) {
            Divider()
        }
        .onAppear {
            findFocused = true
        }
    }
}
