import SwiftUI
import Textual
import MarkSeeCore
import AppKit
import UniformTypeIdentifiers

struct MarkdownView: View {
    let document: MarkdownDocument
    let fileURL: URL?

    @State private var showDefaultAppAlert = false
    @State private var editors: [EditorApp] = []
    @State private var watcher = FileWatcher()
    @AppStorage("preferredEditorURL") private var preferredEditorURL: String = ""
    @State private var copyEventMonitor: Any? = nil

    private var preferredEditor: EditorApp? {
        guard !preferredEditorURL.isEmpty else { return nil }
        let url = URL(filePath: preferredEditorURL)
        return editors.first { $0.url.standardized == url.standardized }
    }

    var body: some View {
        List {
            StructuredText(markdown: watcher.content)
                .textual.structuredTextStyle(.gitHub)
                .textual.textSelection(.enabled)
                .frame(maxWidth: 860)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 32)
                .padding(.vertical, 24)
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets())
        }
        .listStyle(.plain)
        .background(.background)
        .frame(minWidth: 600, minHeight: 400)
        .toolbar {
            editButton
        }
        .onAppear {
            if let fileURL {
                watcher.watch(url: fileURL, initialContent: document.content)
            } else {
                watcher.content = document.content
            }
            loadEditors()
            if !UserDefaults.standard.bool(forKey: "hasPromptedForDefaultApp") {
                showDefaultAppAlert = true
            }
            installCopyEnricher()
        }
        .onDisappear {
            watcher.stop()
            removeCopyEnricher()
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

    // MARK: - Copy enrichment

    /// Installs a local key-down monitor that intercepts ⌘C.
    ///
    /// When the user copies selected text Textual puts both HTML and plain text
    /// (stripped of Markdown syntax) on the pasteboard. This monitor fires after
    /// Textual has already written to the pasteboard, then replaces the plain-text
    /// item with a Markdown reconstruction derived from the HTML item.  The result
    /// is that apps reading HTML (Notion, Pages, Mail…) get rich formatting while
    /// plain-text destinations (Terminal, plain-text editors) receive Markdown.
    private func installCopyEnricher() {
        copyEventMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            guard event.modifierFlags.contains(.command),
                  event.charactersIgnoringModifiers == "c" else {
                return event
            }
            let pasteboard = NSPasteboard.general
            let before = pasteboard.changeCount
            // Dispatch async so Textual's synchronous copy runs first.
            DispatchQueue.main.async {
                guard pasteboard.changeCount != before else { return }
                enrichPasteboard(pasteboard)
            }
            return event
        }
    }

    private func removeCopyEnricher() {
        if let monitor = copyEventMonitor {
            NSEvent.removeMonitor(monitor)
            copyEventMonitor = nil
        }
    }
}

/// Replaces the plain-text item on `pasteboard` with a Markdown representation
/// derived from the HTML item already present.  No-ops when there is no HTML.
private func enrichPasteboard(_ pasteboard: NSPasteboard) {
    guard let html = pasteboard.string(forType: .html) else { return }
    let markdown = htmlToMarkdown(html)
    guard !markdown.isEmpty else { return }
    // Collect all existing types so we can re-declare them.
    let currentTypes = pasteboard.types ?? []
    pasteboard.addTypes([.string], owner: nil)
    pasteboard.setString(markdown, forType: .string)
    _ = currentTypes  // types remain declared; only .string content is replaced
}

struct EditorApp: Identifiable {
    let url: URL
    var id: URL { url }
    var name: String { url.deletingPathExtension().lastPathComponent }
    var icon: NSImage { NSWorkspace.shared.icon(forFile: url.path) }
}
