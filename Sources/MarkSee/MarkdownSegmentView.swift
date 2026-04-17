import SwiftUI
import Textual

/// A single renderable segment within a markdown document.
enum MarkdownSegment: Identifiable, Equatable {
    case markdown(String)
    case codeBlock(language: String?, code: String)
    case mermaid(String)

    var id: String {
        switch self {
        case .markdown(let s): return "md:\(s.hashValue)"
        case .codeBlock(let language, let code): return "code:\(language ?? ""):\(code.hashValue)"
        case .mermaid(let s):  return "mermaid:\(s.hashValue)"
        }
    }
}

/// Splits a markdown string into alternating markdown and mermaid segments.
/// Markdown portions are further split at heading boundaries so that SwiftUI's
/// List can lazily render only visible sections.
func splitSegments(_ markdown: String) -> [MarkdownSegment] {
    var segments: [MarkdownSegment] = []
    var markdownChunk: [Substring] = []
    var fencedChunk: [Substring] = []
    var fenceMarker: String?
    var fenceLanguage: String?

    func flushMarkdown() {
        let text = markdownChunk.joined(separator: "\n")
        if !text.allSatisfy(\.isWhitespace) {
            segments.append(.markdown(text))
        }
        markdownChunk = []
    }

    func flushFence() {
        let code = fencedChunk.joined(separator: "\n")
        if fenceLanguage?.lowercased() == "mermaid" {
            segments.append(.mermaid(code.trimmingCharacters(in: .newlines)))
        } else {
            segments.append(.codeBlock(language: fenceLanguage, code: code))
        }
        fencedChunk = []
        fenceMarker = nil
        fenceLanguage = nil
    }

    for line in markdown.split(separator: "\n", omittingEmptySubsequences: false) {
        let trimmed = line.drop(while: { $0 == " " || $0 == "\t" })

        if let activeMarker = fenceMarker {
            if closesFence(trimmed, marker: activeMarker) {
                flushFence()
            } else {
                fencedChunk.append(line)
            }
            continue
        }

        if let fence = openingFence(in: trimmed) {
            flushMarkdown()
            fenceMarker = fence.marker
            fenceLanguage = fence.language
            continue
        }

        let isHeading = isMarkdownHeading(trimmed)
        if isHeading && !markdownChunk.isEmpty {
            flushMarkdown()
        }
        markdownChunk.append(line)
    }

    if fenceMarker != nil {
        flushFence()
    }
    flushMarkdown()

    return segments
}

private func openingFence(in line: Substring) -> (marker: String, language: String?)? {
    let marker: String
    if line.hasPrefix("```") {
        marker = "```"
    } else if line.hasPrefix("~~~") {
        marker = "~~~"
    } else {
        return nil
    }

    let info = line.dropFirst(marker.count).trimmingCharacters(in: .whitespaces)
    return (marker, info.isEmpty ? nil : info)
}

private func closesFence(_ line: Substring, marker: String) -> Bool {
    line.hasPrefix(marker)
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
        case .codeBlock(let language, let code):
            if findQuery.isEmpty {
                StructuredText(markdown: fencedMarkdown(language: language, code: code))
                    .textual.structuredTextStyle(.gitHub)
                    .textual.textSelection(.enabled)
            } else {
                SearchableCodeBlockView(language: language, code: code, findQuery: findQuery)
            }
        case .mermaid(let diagram):
            MermaidView(diagram: diagram)
                .frame(height: 300)
                .frame(maxWidth: .infinity)
                .accessibilityLabel("Mermaid diagram")
        }
    }
}

private func fencedMarkdown(language: String?, code: String) -> String {
    let info = language.map { " \($0)" } ?? ""
    return "```\(info)\n\(code)\n```"
}

private struct SearchableCodeBlockView: View {
    let language: String?
    let code: String
    let findQuery: String

    @State private var tokens: [CodeSyntaxToken] = []

    var body: some View {
        ScrollView(.horizontal) {
            Text(highlightedCode)
                .font(.system(.body, design: .monospaced))
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 8)
                .padding(.horizontal, 14)
        }
        .background(Color(nsColor: .textBackgroundColor).opacity(0.45))
        .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .stroke(Color.secondary.opacity(0.25), lineWidth: 1)
        )
        .accessibilityLabel(language.map { "Code block, \($0)" } ?? "Code block")
        .task(id: "\(language ?? "")\u{0}\(code)") {
            tokens = await CodeSyntaxTokenizer.shared.tokenize(code: code, language: language)
        }
    }

    private var highlightedCode: AttributedString {
        var result = AttributedString()
        for token in tokens.isEmpty ? [CodeSyntaxToken(content: code, type: "plain")] : tokens {
            var content = AttributedString(token.content)
            var attributes = AttributeContainer()
            attributes.foregroundColor = color(forTokenType: token.type)
            content.mergeAttributes(attributes, mergePolicy: .keepNew)
            result.append(content)
        }

        guard !findQuery.isEmpty else { return result }
        let plainText = String(result.characters)
        var searchRange = plainText.startIndex..<plainText.endIndex
        let options: String.CompareOptions = [.caseInsensitive, .diacriticInsensitive]

        while let matchRange = plainText.range(of: findQuery, options: options, range: searchRange) {
            let startOffset = plainText.distance(from: plainText.startIndex, to: matchRange.lowerBound)
            let endOffset = plainText.distance(from: plainText.startIndex, to: matchRange.upperBound)
            let attrStart = result.characters.index(result.startIndex, offsetBy: startOffset)
            let attrEnd = result.characters.index(result.startIndex, offsetBy: endOffset)

            var container = AttributeContainer()
            container.backgroundColor = Color.yellow.opacity(0.5)
            result[attrStart..<attrEnd].mergeAttributes(container, mergePolicy: .keepNew)

            searchRange = matchRange.upperBound..<plainText.endIndex
        }

        return result
    }

    private func color(forTokenType type: String) -> Color {
        switch type {
        case "keyword", "literal", "boolean":
            return Color(red: 0.607592, green: 0.137526, blue: 0.576284)
        case "builtin":
            return Color(red: 0.224543, green: 0, blue: 0.628029)
        case "string", "regex":
            return Color(red: 0.77, green: 0.102, blue: 0.086)
        case "char", "number":
            return Color(red: 0.11, green: 0, blue: 0.81)
        case "url":
            return Color(red: 0.055, green: 0.055, blue: 1)
        case "class-name":
            return Color(red: 0.109812, green: 0.272761, blue: 0.288691)
        case "function", "function-name":
            return Color(red: 0.194184, green: 0.429349, blue: 0.454553)
        case "variable", "property", "constant":
            return Color(red: 0.194184, green: 0.429349, blue: 0.454553)
        case "comment", "block-comment", "doc-comment":
            return Color(red: 0.36526, green: 0.421879, blue: 0.475154)
        case "preprocessor", "directive":
            return Color(red: 0.391471, green: 0.220311, blue: 0.124457)
        case "attribute", "attr-name":
            return Color(red: 0.505801, green: 0.371396, blue: 0.012096)
        case "inserted":
            return Color(red: 0.203922, green: 0.780392, blue: 0.349020)
        case "deleted":
            return Color(red: 1, green: 0.219608, blue: 0.235294)
        default:
            return .primary
        }
    }
}
