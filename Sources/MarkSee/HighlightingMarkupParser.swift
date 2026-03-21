import SwiftUI
import Textual

/// A ``MarkupParser`` that wraps Textual's default Markdown parser and adds
/// background-color highlights on every occurrence of a search query in the
/// rendered text.  Case- and diacritic-insensitive matching is used, consistent
/// with ``findMatches(in:query:)``.
@MainActor
struct HighlightingMarkupParser: MarkupParser {
    let query: String

    private static let base = AttributedStringMarkdownParser(
        baseURL: nil,
        syntaxExtensions: [.math]
    )

    func attributedString(for input: String) throws -> AttributedString {
        var result = try Self.base.attributedString(for: input)
        guard !query.isEmpty else { return result }

        // Search in the rendered plain text (markdown syntax stripped).
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
