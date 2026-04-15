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
    @AppStorage("theme") private var themeRawValue: String = MarkSeeTheme.system.rawValue
    private var theme: MarkSeeTheme { MarkSeeTheme(rawValue: themeRawValue) ?? .system }
    @State private var copyEventMonitor: Any? = nil
    @State private var scrollEventMonitor: Any? = nil

    // MARK: - TOC
    @AppStorage("tocVisible") private var tocVisible = false
    @State private var headings: [MarkdownHeading] = []

    // MARK: - Cached segments
    @State private var segments: [MarkdownSegment] = []

    // MARK: - Find
    @State private var isShowingFind = false
    @State private var findQuery = ""
    @State private var searchMatches: [SearchMatch] = []
    @State private var findMatchIndex = 0
    @State private var findTask: Task<Void, Never>? = nil

    private var preferredEditor: EditorApp? {
        guard !preferredEditorURL.isEmpty else { return nil }
        let url = URL(filePath: preferredEditorURL)
        return editors.first { $0.url.standardized == url.standardized }
    }

    var body: some View {
        HStack(spacing: 0) {
            if tocVisible && !headings.isEmpty {
                TOCSidebar(headings: headings) { heading in
                    scrollToFraction(CGFloat(scrollFraction(
                        forCharacterOffset: heading.characterOffset,
                        totalLength: watcher.content.count
                    )))
                }
                Divider()
            }
            VStack(spacing: 0) {
                if isShowingFind {
                    FindBar(
                        query: $findQuery,
                        matchCount: searchMatches.count,
                        currentMatchIndex: findMatchIndex,
                        onNext: nextMatch,
                        onPrevious: previousMatch,
                        onDismiss: dismissFind
                    )
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
                List {
                    ForEach(Array(segments.enumerated()), id: \.offset) { index, segment in
                        MarkdownSegmentView(segment: segment, findQuery: findQuery)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .frame(maxWidth: 860, alignment: .leading)
                            .frame(maxWidth: .infinity)
                            .padding(.horizontal, 32)
                            .padding(.top, index > 0 ? 20 : 0)
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                            .listRowInsets(EdgeInsets())
                    }
                }
                .listStyle(.plain)
                .background(.background)
            }
        }
        .background(WindowFrameObserver(fileURL: fileURL))
        .frame(minWidth: 600, minHeight: 400)
        .focusedValue(\.isShowingFind, $isShowingFind)
        .focusedValue(\.printAction, printDocument)
        .preferredColorScheme(theme.colorScheme)
        .toolbar {
            tocToggleButton
            editButton
        }
        .onChange(of: findQuery) { _, _ in updateFindMatches() }
        .onChange(of: watcher.content) { _, _ in
            updateFindMatches()
            recomputeCaches()
        }
        .onKeyPress(.escape) {
            guard isShowingFind else { return .ignored }
            dismissFind()
            return .handled
        }
        .onAppear {
            if let fileURL {
                watcher.watch(url: fileURL, initialContent: document.content)
                noteRecentDocument(fileURL)
            } else {
                watcher.content = document.content
            }
            recomputeCaches()
            loadEditors()
            if !UserDefaults.standard.bool(forKey: "hasPromptedForDefaultApp") {
                showDefaultAppAlert = true
            }
            installCopyEnricher()
            installScrollForwarder()
        }
        .onDisappear {
            watcher.stop()
            removeCopyEnricher()
            removeScrollForwarder()
            findTask?.cancel()
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
    private var tocToggleButton: some View {
        if !headings.isEmpty {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) { tocVisible.toggle() }
            } label: {
                Label("Table of Contents", systemImage: "list.bullet.indent")
            }
            .help(tocVisible ? "Hide Table of Contents" : "Show Table of Contents")
            .accessibilityLabel(tocVisible ? "Hide Table of Contents" : "Show Table of Contents")
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

    // MARK: - Print

    private func printDocument() {
        let printView = PrintableMarkdownView(content: watcher.content)
        let hostingView = NSHostingView(rootView: printView)
        // Size to a standard US Letter page width (points at 72 dpi).
        let pageWidth: CGFloat = 8.5 * 72
        hostingView.frame = CGRect(x: 0, y: 0, width: pageWidth, height: 1)
        // Let the view compute its natural height.
        hostingView.frame.size.height = hostingView.fittingSize.height

        let printInfo = NSPrintInfo.shared.copy() as! NSPrintInfo
        printInfo.horizontalPagination = .fit
        printInfo.verticalPagination = .automatic
        printInfo.isHorizontallyCentered = false
        printInfo.isVerticallyCentered = false
        printInfo.leftMargin = 54
        printInfo.rightMargin = 54
        printInfo.topMargin = 54
        printInfo.bottomMargin = 54

        let op = NSPrintOperation(view: hostingView, printInfo: printInfo)
        op.showsPrintPanel = true
        op.showsProgressPanel = true
        op.run()
    }

    // MARK: - Cached recomputation

    private func recomputeCaches() {
        segments = splitSegments(watcher.content)
        headings = extractHeadings(from: watcher.content)
    }

    // MARK: - Find

    private func updateFindMatches() {
        findTask?.cancel()
        let content = watcher.content
        let query = findQuery
        findTask = Task {
            // Run the expensive Unicode search off the main actor.
            let matches = await Task.detached {
                findMatches(in: content, query: query)
            }.value
            guard !Task.isCancelled else { return }
            searchMatches = matches
            findMatchIndex = 0
            scrollToCurrentMatch()
        }
    }

    private func nextMatch() {
        guard !searchMatches.isEmpty else { return }
        findMatchIndex = (findMatchIndex + 1) % searchMatches.count
        scrollToCurrentMatch()
    }

    private func previousMatch() {
        guard !searchMatches.isEmpty else { return }
        findMatchIndex = (findMatchIndex - 1 + searchMatches.count) % searchMatches.count
        scrollToCurrentMatch()
    }

    private func dismissFind() {
        withAnimation(.easeInOut(duration: 0.15)) { isShowingFind = false }
        findQuery = ""
        searchMatches = []
        findMatchIndex = 0
    }

    private func scrollToCurrentMatch() {
        guard !searchMatches.isEmpty else { return }
        let match = searchMatches[findMatchIndex]
        let fraction = scrollFraction(
            forCharacterOffset: match.characterOffset,
            totalLength: watcher.content.count
        )
        scrollToFraction(CGFloat(fraction))
    }

    @MainActor
    private func scrollToFraction(_ fraction: CGFloat) {
        guard let window = NSApp.keyWindow,
              let scrollView = window.contentView?.documentScrollView else { return }
        let contentHeight = scrollView.documentView?.bounds.height ?? 0
        let visibleHeight = scrollView.contentSize.height
        let maxY = max(0, contentHeight - visibleHeight)
        scrollView.documentView?.scroll(CGPoint(x: 0, y: maxY * fraction))
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

    // MARK: - Scroll forwarding

    /// Installs a local scroll-wheel monitor that forwards vertical scroll events from
    /// nested scroll views (e.g. code-block horizontal scrollers) to the outermost
    /// scroll view so that the document continues to scroll even when the pointer is
    /// positioned over a code block.
    private func installScrollForwarder() {
        scrollEventMonitor = NSEvent.addLocalMonitorForEvents(matching: .scrollWheel) { event in
            guard isMainlyVertical(
                deltaX: event.scrollingDeltaX,
                deltaY: event.scrollingDeltaY
            ) else { return event }

            guard let window = event.window,
                  let hitView = window.contentView?.hitTest(event.locationInWindow) else {
                return event
            }

            // If the pointer is inside nested scroll views (code block inside List),
            // forward the vertical event to the outermost (document) scroll view.
            guard let outermost = outermostNestedScrollView(from: hitView) else {
                return event
            }

            outermost.scrollWheel(with: event)
            return nil
        }
    }

    private func removeScrollForwarder() {
        if let monitor = scrollEventMonitor {
            NSEvent.removeMonitor(monitor)
            scrollEventMonitor = nil
        }
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

func noteRecentDocument(_ url: URL) {
    var paths = UserDefaults.standard.stringArray(forKey: "recentDocumentPaths") ?? []
    paths.removeAll { $0 == url.path }
    paths.insert(url.path, at: 0)
    UserDefaults.standard.set(Array(paths.prefix(20)), forKey: "recentDocumentPaths")
}

// MARK: - NSView helpers

private extension NSView {
    /// Returns the largest NSScrollView in the subtree, used to find the document scroller.
    var documentScrollView: NSScrollView? {
        var all: [NSScrollView] = []
        collectScrollViews(into: &all)
        return all.max { $0.bounds.height < $1.bounds.height }
    }

    private func collectScrollViews(into list: inout [NSScrollView]) {
        if let sv = self as? NSScrollView { list.append(sv) }
        for sub in subviews { sub.collectScrollViews(into: &list) }
    }
}

struct EditorApp: Identifiable {
    let url: URL
    var id: URL { url }
    var name: String { url.deletingPathExtension().lastPathComponent }
    var icon: NSImage { NSWorkspace.shared.icon(forFile: url.path) }
}
