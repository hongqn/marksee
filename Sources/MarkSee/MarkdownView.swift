import SwiftUI
import Textual
import MarkSeeCore
import AppKit

struct MarkdownView: View {
    let document: MarkdownDocument
    let fileURL: URL?

    @State private var showDefaultAppAlert = false
    @State private var editors: [EditorApp] = []
    @AppStorage("preferredEditorURL") private var preferredEditorURL: String = ""

    private var preferredEditor: EditorApp? {
        guard !preferredEditorURL.isEmpty else { return nil }
        let url = URL(filePath: preferredEditorURL)
        return editors.first { $0.url.standardized == url.standardized }
    }

    var body: some View {
        ScrollView {
            StructuredText(markdown: document.content)
                .textual.structuredTextStyle(.gitHub)
                .padding(.horizontal, 32)
                .padding(.vertical, 24)
                .frame(maxWidth: 860)
                .frame(maxWidth: .infinity)
        }
        .background(.background)
        .frame(minWidth: 600, minHeight: 400)
        .toolbar {
            editButton
        }
        .onAppear {
            loadEditors()
            if !UserDefaults.standard.bool(forKey: "hasPromptedForDefaultApp") {
                showDefaultAppAlert = true
            }
        }
        .alert("Make MarkSee your default Markdown viewer?", isPresented: $showDefaultAppAlert) {
            Button("Open Settings") {
                UserDefaults.standard.set(true, forKey: "hasPromptedForDefaultApp")
                NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
            }
            Button("Not Now", role: .cancel) {
                UserDefaults.standard.set(true, forKey: "hasPromptedForDefaultApp")
            }
        } message: {
            Text("You can set MarkSee as the default app for .md files in Settings.")
        }
    }

    @ViewBuilder
    private var editButton: some View {
        if editors.count == 1 {
            Button {
                open(in: editors[0])
            } label: {
                Label("Edit", systemImage: "pencil")
            }
            .disabled(fileURL == nil)
        } else if editors.count > 1 {
            Menu {
                ForEach(editors) { editor in
                    Button {
                        preferredEditorURL = editor.url.path
                        open(in: editor)
                    } label: {
                        HStack {
                            Image(nsImage: editor.icon)
                            Text(editor.name)
                        }
                    }
                    .badge(editor.url.standardized == preferredEditor?.url.standardized ? "✓" : "")
                }
            } label: {
                Label("Edit", systemImage: "pencil")
            } primaryAction: {
                let target = preferredEditor ?? editors[0]
                open(in: target)
            }
            .disabled(fileURL == nil)
        }
    }

    private func loadEditors() {
        guard let fileURL else { return }
        let selfBundleURL = Bundle.main.bundleURL.standardized
        editors = NSWorkspace.shared.urlsForApplications(toOpen: fileURL)
            .filter { $0.standardized != selfBundleURL }
            .map { EditorApp(url: $0) }
    }

    private func open(in editor: EditorApp) {
        guard let fileURL else { return }
        NSWorkspace.shared.open(
            [fileURL],
            withApplicationAt: editor.url,
            configuration: NSWorkspace.OpenConfiguration()
        )
    }
}

struct EditorApp: Identifiable {
    let url: URL
    var id: URL { url }
    var name: String { url.deletingPathExtension().lastPathComponent }
    var icon: NSImage { NSWorkspace.shared.icon(forFile: url.path) }
}
