import SwiftUI
import Textual

/// A single renderable segment within a markdown document.
enum MarkdownSegment: Identifiable, Equatable {
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
/// Markdown portions are further split at heading boundaries so that SwiftUI's
/// List can lazily render only visible sections.
func splitSegments(_ markdown: String) -> [MarkdownSegment] {
    let pattern = #"```mermaid\n([\s\S]*?)```"#
    guard let regex = try? NSRegularExpression(pattern: pattern) else {
        return splitByHeadings(markdown)
    }
    let nsString = markdown as NSString
    let range = NSRange(location: 0, length: nsString.length)
    let matches = regex.matches(in: markdown, range: range)
    guard !matches.isEmpty else { return splitByHeadings(markdown) }

    var segments: [MarkdownSegment] = []
    var cursor = markdown.startIndex

    for match in matches {
        // Text before this mermaid block
        if let fullRange = Range(match.range, in: markdown) {
            let before = String(markdown[cursor..<fullRange.lowerBound])
            if !before.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                segments.append(contentsOf: splitByHeadings(before))
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
        segments.append(contentsOf: splitByHeadings(tail))
    }
    return segments
}

/// Splits markdown text into segments at heading boundaries, respecting code fences.
private func splitByHeadings(_ markdown: String) -> [MarkdownSegment] {
    guard !markdown.isEmpty else { return [] }

    var segments: [MarkdownSegment] = []
    var currentChunk: [Substring] = []
    var inCodeFence = false

    for line in markdown.split(separator: "\n", omittingEmptySubsequences: false) {
        let trimmed = line.drop(while: { $0 == " " || $0 == "\t" })

        if trimmed.hasPrefix("```") || trimmed.hasPrefix("~~~") {
            inCodeFence.toggle()
        }

        let isHeading = !inCodeFence && isMarkdownHeading(trimmed)

        if isHeading && !currentChunk.isEmpty {
            let text = currentChunk.joined(separator: "\n")
            if !text.allSatisfy(\.isWhitespace) {
                segments.append(.markdown(text))
            }
            currentChunk = []
        }

        currentChunk.append(line)
    }

    if !currentChunk.isEmpty {
        let text = currentChunk.joined(separator: "\n")
        if !text.allSatisfy(\.isWhitespace) {
            segments.append(.markdown(text))
        }
    }

    return segments
}

/// Returns true when `line` is an ATX heading (1–6 `#` followed by a space or end-of-line).
private func isMarkdownHeading(_ line: Substring) -> Bool {
    guard line.first == "#" else { return false }
    let hashes = line.prefix(while: { $0 == "#" })
    guard hashes.count >= 1 && hashes.count <= 6 else { return false }
    return hashes.count == line.count || line[hashes.endIndex] == " "
}

/// Renders a single document segment — either markdown text or a Mermaid diagram.
struct MarkdownSegmentView: View {
    let segment: MarkdownSegment
    /// Active search query; non-empty enables match highlighting.
    var findQuery: String = ""

    var body: some View {
        switch segment {
        case .markdown(let text):
            StructuredText(text, parser: HighlightingMarkupParser(query: findQuery))
                .id(findQuery)
                .textual.structuredTextStyle(.gitHub)
                .textual.textSelection(.enabled)
        case .mermaid(let diagram):
            MermaidView(diagram: diagram)
                .frame(height: 300)
                .frame(maxWidth: .infinity)
                .accessibilityLabel("Mermaid diagram")
        }
    }
}
