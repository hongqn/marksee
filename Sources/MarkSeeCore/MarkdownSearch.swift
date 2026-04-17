import Foundation

/// A single text match within a markdown document.
public struct SearchMatch: Equatable, Sendable {
    /// Byte-offset of the match from the start of the document string.
    public let characterOffset: Int
    /// Length of the matched substring in characters.
    public let matchLength: Int

    public init(characterOffset: Int, matchLength: Int) {
        self.characterOffset = characterOffset
        self.matchLength = matchLength
    }
}

/// Returns all case-insensitive, diacritic-insensitive occurrences of `query` in `text`.
/// Returns an empty array when `query` is empty.
public func findMatches(in text: String, query: String) -> [SearchMatch] {
    guard !query.isEmpty else { return [] }
    var matches: [SearchMatch] = []
    var searchRange = text.startIndex..<text.endIndex
    while let range = text.range(
        of: query,
        options: [.caseInsensitive, .diacriticInsensitive],
        range: searchRange
    ) {
        let offset = text.distance(from: text.startIndex, to: range.lowerBound)
        let length = text.distance(from: range.lowerBound, to: range.upperBound)
        matches.append(SearchMatch(characterOffset: offset, matchLength: length))
        searchRange = range.upperBound..<text.endIndex
    }
    return matches
}

/// Returns the fractional vertical scroll position (0.0 – 1.0) for a given character
/// offset in a document of `totalLength` characters.  Clamps to [0, 1].
public func scrollFraction(forCharacterOffset offset: Int, totalLength: Int) -> Double {
    guard totalLength > 0, offset > 0 else { return 0 }
    return min(1, max(0, Double(offset) / Double(totalLength)))
}

/// Returns Markdown text that participates in visible search highlighting.
/// Fenced code blocks are excluded because they are rendered through Textual's
/// syntax highlighter, which does not preserve the search background attribute.
public func markdownTextExcludingFencedCodeBlocks(_ markdown: String) -> String {
    var output: [Substring] = []
    var inCodeFence = false
    var fenceMarker: String?

    for line in markdown.split(separator: "\n", omittingEmptySubsequences: false) {
        let trimmed = line.drop(while: { $0 == " " || $0 == "\t" })
        if let marker = openingFenceMarker(in: trimmed) {
            if inCodeFence {
                if marker == fenceMarker {
                    inCodeFence = false
                    fenceMarker = nil
                }
            } else {
                inCodeFence = true
                fenceMarker = marker
            }
            continue
        }

        if !inCodeFence {
            output.append(line)
        }
    }

    return output.joined(separator: "\n")
}

private func openingFenceMarker(in line: Substring) -> String? {
    if line.hasPrefix("```") { return "```" }
    if line.hasPrefix("~~~") { return "~~~" }
    return nil
}
