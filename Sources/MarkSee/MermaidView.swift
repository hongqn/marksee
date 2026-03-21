import SwiftUI
import WebKit

/// Renders a Mermaid diagram string using WKWebView and the Mermaid JS library
/// (loaded from a local HTML page bundled as a resource string — no CDN, no network).
struct MermaidView: NSViewRepresentable {
    let diagram: String

    func makeNSView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.preferences.setValue(true, forKey: "developerExtrasEnabled")
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator
        webView.setValue(false, forKey: "drawsBackground")
        return webView
    }

    func updateNSView(_ webView: WKWebView, context: Context) {
        // Load from the bundle directory so the HTML can reference mermaid.min.js locally.
        if let resourceDir = Bundle.module.resourceURL {
            let htmlURL = resourceDir.appendingPathComponent("mermaid-diagram.html")
            let html = buildHTML(for: diagram, useLocalJS: true)
            try? html.write(to: htmlURL, atomically: true, encoding: .utf8)
            webView.loadFileURL(htmlURL, allowingReadAccessTo: resourceDir)
        } else {
            webView.loadHTMLString(buildHTML(for: diagram, useLocalJS: false), baseURL: nil)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    class Coordinator: NSObject, WKNavigationDelegate {
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            // After loading, ask the page for the rendered SVG height and resize.
            webView.evaluateJavaScript("document.body.scrollHeight") { result, _ in
                if let height = result as? CGFloat, height > 0 {
                    webView.frame.size.height = height
                }
            }
        }
    }

    // MARK: - HTML generation

    private func buildHTML(for diagram: String, useLocalJS: Bool) -> String {
        let scriptTag = useLocalJS
            ? "<script src=\"mermaid.min.js\"></script><script>mermaid.initialize({ startOnLoad: true, theme: 'base' });</script>"
            : "<script type=\"module\">import mermaid from 'https://cdn.jsdelivr.net/npm/mermaid@11/dist/mermaid.esm.min.mjs';mermaid.initialize({ startOnLoad: true, theme: 'base' });</script>"
        return """
        <!DOCTYPE html>
        <html>
        <head>
        <meta charset="utf-8">
        <style>
          body { margin: 0; padding: 0; background: transparent; }
          #diagram { display: flex; justify-content: center; }
          #diagram svg { max-width: 100%; height: auto; }
        </style>
        </head>
        <body>
        <div id="diagram">
          <pre class="mermaid">\(escapeHTML(diagram))</pre>
        </div>
        \(scriptTag)
        </body>
        </html>
        """
    }

    private func escapeHTML(_ text: String) -> String {
        text
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
    }
}

// MARK: - Mermaid block extraction

/// Strips ` ```mermaid…``` ` fenced blocks from markdown, returning
/// a processed string with those blocks replaced by a placeholder, and
/// an ordered list of the extracted diagram strings.
public struct MermaidExtractResult {
    /// Markdown with mermaid blocks replaced by `<!-- mermaid:N -->` placeholders.
    public let processedMarkdown: String
    /// Extracted diagram sources in order of appearance.
    public let diagrams: [String]
}

/// Extracts all ` ```mermaid…``` ` fenced code blocks from `markdown`.
/// Returns the cleaned markdown and the diagram sources in order.
public func extractMermaidBlocks(from markdown: String) -> MermaidExtractResult {
    var diagrams: [String] = []
    var result = markdown
    let pattern = #"```mermaid\n([\s\S]*?)```"#
    guard let regex = try? NSRegularExpression(pattern: pattern) else {
        return MermaidExtractResult(processedMarkdown: markdown, diagrams: [])
    }
    let range = NSRange(markdown.startIndex..., in: markdown)
    // Collect matches in reverse order so replacements don't invalidate ranges.
    let matches = regex.matches(in: markdown, range: range).reversed()
    for match in matches {
        let index = diagrams.count
        if let contentRange = Range(match.range(at: 1), in: markdown) {
            diagrams.insert(String(markdown[contentRange]).trimmingCharacters(in: .newlines), at: 0)
        }
        if let fullRange = Range(match.range, in: result) {
            result.replaceSubrange(fullRange, with: "\n<!-- mermaid:\(diagrams.count - index - 1) -->\n")
        }
    }
    return MermaidExtractResult(processedMarkdown: result, diagrams: diagrams)
}
