import SwiftUI
import Textual

/// A ``MarkupParser`` that wraps Textual's default Markdown parser and adds
/// background-color highlights on every occurrence of a search query in the
/// rendered text.  Case- and diacritic-insensitive matching is used, consistent
/// with ``findMatches(in:query:)``.
@MainActor
struct HighlightingMarkupParser: MarkupParser, Equatable {
    let query: String

    nonisolated static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.query == rhs.query
    }

    private static let base = AttributedStringMarkdownParser(
        baseURL: nil,
        syntaxExtensions: [.math]
    )

    /// Caches base (unhighlighted) attributed strings to avoid re-parsing
    /// markdown when only the search query changes.
    private static var parsedCache: [String: AttributedString] = [:]

    static func clearCache() {
        parsedCache.removeAll()
    }

    func attributedString(for input: String) throws -> AttributedString {
        let baseResult: AttributedString
        if let cached = Self.parsedCache[input] {
            baseResult = cached
        } else {
            baseResult = try Self.base.attributedString(for: input)
            Self.parsedCache[input] = baseResult
        }
        guard !query.isEmpty else { return baseResult }

        // Apply highlights on a copy of the cached base.
        var result = baseResult
        let plainText = String(result.characters)
        var searchRange = plainText.startIndex..<plainText.endIndex
        let options: String.CompareOptions = [.caseInsensitive, .diacriticInsensitive]

        while let matchRange = plainText.range(of: query, options: options, range: searchRange) {
            let startOffset = plainText.distance(from: plainText.startIndex, to: matchRange.lowerBound)
            let endOffset   = plainText.distance(from: plainText.startIndex, to: matchRange.upperBound)
            let attrStart   = result.characters.index(result.startIndex, offsetBy: startOffset)
            let attrEnd     = result.characters.index(result.startIndex, offsetBy: endOffset)

            var container = AttributeContainer()
            container.backgroundColor = Color.yellow.opacity(0.5)
            result[attrStart..<attrEnd].mergeAttributes(
                container,
                mergePolicy: AttributedString.AttributeMergePolicy.keepNew
            )

            searchRange = matchRange.upperBound..<plainText.endIndex
        }
        return result
    }
}
