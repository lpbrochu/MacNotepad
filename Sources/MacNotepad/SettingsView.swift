import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var document: NotepadDocument

    var body: some View {
        Form {
            Section {
                Picker("Editor Font", selection: $document.selectedFontID) {
                    ForEach(EditorFontOption.all) { font in
                        Text(font.displayName)
                            .tag(font.id)
                    }
                }
                .pickerStyle(.menu)

                HStack {
                    Text("Preview")
                    Text("The quick brown fox jumps over 0123456789")
                        .font(Font(document.selectedFontOption.font(size: 14)))
                        .padding(.vertical, 6)
                }

                Stepper(value: $document.fontSize, in: 8...48, step: 1) {
                    Text("Font Size: \(Int(document.fontSize))")
                }
            } header: {
                Text("Editor")
            }
        }
        .padding(20)
        .frame(width: 440)
    }
}
