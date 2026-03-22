import Foundation

/// A heading extracted from a markdown document.
public struct MarkdownHeading: Equatable, Sendable {
    /// ATX heading level (1–6).
    public let level: Int
    /// Heading text with inline markup stripped.
    public let title: String
    /// Character offset of the heading line from the start of the document.
    public let characterOffset: Int

    public init(level: Int, title: String, characterOffset: Int) {
        self.level = level
        self.title = title
        self.characterOffset = characterOffset
    }
}

/// Parses ATX-style headings (`# H1`, `## H2`, …) from `markdown`.
///
/// Setext-style headings (underline `===` / `---`) are intentionally not
/// supported to keep the parser simple; they are uncommon in practice.
/// Code fences are skipped so headings inside ` ```…``` ` blocks are ignored.
public func extractHeadings(from markdown: String) -> [MarkdownHeading] {
    var headings: [MarkdownHeading] = []
    var insideCodeFence = false
    var charOffset = 0  // running character count — O(n) total, avoids O(n²) distance() calls

    for line in markdown.split(separator: "\n", omittingEmptySubsequences: false) {
        let lineStr = String(line)

        // Toggle code-fence state on opening/closing ``` or ~~~
        if lineStr.hasPrefix("```") || lineStr.hasPrefix("~~~") {
            insideCodeFence.toggle()
        }

        if !insideCodeFence, let heading = parseATXHeading(from: lineStr, offset: charOffset) {
            headings.append(heading)
        }

        // Advance past this line and the newline character.
        charOffset += lineStr.count + 1
    }
    return headings
}

// MARK: - Private helpers

private func parseATXHeading(from line: String, offset: Int) -> MarkdownHeading? {
    // ATX heading: 1–6 `#` characters followed by a space (or end of line).
    var index = line.startIndex
    var level = 0
    while index < line.endIndex, line[index] == "#", level < 6 {
        level += 1
        index = line.index(after: index)
    }
    guard level > 0 else { return nil }
    // Must be followed by a space or be end of line (e.g. `#` alone is valid H1).
    if index < line.endIndex {
        guard line[index] == " " else { return nil }
        index = line.index(after: index)
    }
    let raw = String(line[index...])
    // Strip optional trailing `#` characters used as closing markers.
    let trimmed = raw.replacingOccurrences(of: #"\s+#+\s*$"#, with: "", options: .regularExpression)
    let title = stripInlineMarkdown(trimmed.trimmingCharacters(in: .whitespaces))
    return MarkdownHeading(level: level, title: title, characterOffset: offset)
}

/// Removes common inline markdown syntax so the TOC shows plain text.
private func stripInlineMarkdown(_ text: String) -> String {
    var result = text
    // Bold/italic: **…**, __…__, *…*, _…_
    result = result.replacingOccurrences(of: #"\*{1,3}([^*]+)\*{1,3}"#, with: "$1", options: .regularExpression)
    result = result.replacingOccurrences(of: #"_{1,3}([^_]+)_{1,3}"#, with: "$1", options: .regularExpression)
    // Inline code: `…`
    result = result.replacingOccurrences(of: #"`([^`]*)`"#, with: "$1", options: .regularExpression)
    // Links: [text](url)
    result = result.replacingOccurrences(of: #"\[([^\]]*)\]\([^)]*\)"#, with: "$1", options: .regularExpression)
    return result
}
