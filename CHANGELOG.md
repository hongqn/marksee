## 0.2.0 - 2026-03-31

### Features
- Render Mermaid diagrams via embedded WKWebView
- Enable LaTeX math rendering via Textual's built-in .math extension
- Add System / GitHub Light / GitHub Dark theme switching
- Add collapsible Table of Contents sidebar
- Add in-document search with Cmd+F and match highlighting
- Add Cmd+P print/export-to-PDF support
- Restore open documents and window frames across launches
- Copy selected text as both rich text and Markdown
- Live reload on file change
- Add welcome window on launch
- Add Settings window with file association configuration
- Improve accessibility across WelcomeView and FindBar
- Add signing and notarization infrastructure

### Fixes
- Use viewDidMoveToWindow for reliable window frame save/restore
- Record recent document at open time, not onAppear
- Reactively update recent docs list when UserDefaults changes
- Restore recent documents list across app restarts
- Forward vertical scroll events from code block to document
- Enable text selection by switching ScrollView to List
- Prevent new document window from closing when opening from Welcome screen
- Prevent crash on launch by using native .suppressed launch behavior

### Performance
- Async search, O(n) heading extraction, performance benchmarks

### Documentation
- Add LaTeX math and Mermaid diagram features to README
