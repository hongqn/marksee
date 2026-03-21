import SwiftUI
import Textual

/// A single renderable segment within a markdown document.
enum MarkdownSegment: Identifiable {
    case markdown(String)
    case mermaid(String)

    var id: String {
        switch self {
        case .markdown(let s): return "md:\(s.hashValue)"
        case .mermaid(let s):  return "mermaid:\(s.hashValue)"
        }
    }
}

/// Splits a markdown string into alternating markdown and mermaid segments.
func splitSegments(_ markdown: String) -> [MarkdownSegment] {
    let pattern = #"```mermaid\n([\s\S]*?)```"#
    guard let regex = try? NSRegularExpression(pattern: pattern) else {
        return [.markdown(markdown)]
    }
    let nsString = markdown as NSString
    let range = NSRange(location: 0, length: nsString.length)
    let matches = regex.matches(in: markdown, range: range)
    guard !matches.isEmpty else { return [.markdown(markdown)] }

    var segments: [MarkdownSegment] = []
    var cursor = markdown.startIndex

    for match in matches {
        // Text before this mermaid block
        if let fullRange = Range(match.range, in: markdown) {
            let before = String(markdown[cursor..<fullRange.lowerBound])
            if !before.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                segments.append(.markdown(before))
            }
            // The mermaid diagram source (capture group 1)
            if let contentRange = Range(match.range(at: 1), in: markdown) {
                let diagram = String(markdown[contentRange]).trimmingCharacters(in: .newlines)
                segments.append(.mermaid(diagram))
            }
            cursor = fullRange.upperBound
        }
    }
    // Remaining text after the last mermaid block
    let tail = String(markdown[cursor...])
    if !tail.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
        segments.append(.markdown(tail))
    }
    return segments
}

/// Renders a single document segment — either markdown text or a Mermaid diagram.
struct MarkdownSegmentView: View {
    let segment: MarkdownSegment
    /// Active search query; non-empty enables match highlighting.
    var findQuery: String = ""

    var body: some View {
        switch segment {
        case .markdown(let text):
            if findQuery.isEmpty {
                StructuredText(markdown: text, syntaxExtensions: [.math])
                    .textual.structuredTextStyle(.gitHub)
                    .textual.textSelection(.enabled)
            } else {
                StructuredText(text, parser: HighlightingMarkupParser(query: findQuery))
                    .textual.structuredTextStyle(.gitHub)
                    .textual.textSelection(.enabled)
            }
        case .mermaid(let diagram):
            MermaidView(diagram: diagram)
                .frame(height: 300)
                .frame(maxWidth: .infinity)
                .accessibilityLabel("Mermaid diagram")
        }
    }
}
