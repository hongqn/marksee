import Testing
@testable import MarkSeeCore

@Suite("MarkdownSearch")
struct MarkdownSearchTests {

    // MARK: - findMatches(in:query:)

    @Test("empty query returns no matches")
    func emptyQuery() {
        #expect(findMatches(in: "Hello World", query: "").isEmpty)
    }

    @Test("no matches returns empty array")
    func noMatches() {
        #expect(findMatches(in: "Hello World", query: "xyz").isEmpty)
    }

    @Test("single match has correct offset")
    func singleMatch() {
        let matches = findMatches(in: "Hello World", query: "World")
        #expect(matches.count == 1)
        #expect(matches[0].characterOffset == 6)
        #expect(matches[0].matchLength == 5)
    }

    @Test("multiple matches are all found")
    func multipleMatches() {
        let matches = findMatches(in: "foo bar foo baz foo", query: "foo")
        #expect(matches.count == 3)
        #expect(matches[0].characterOffset == 0)
        #expect(matches[1].characterOffset == 8)
        #expect(matches[2].characterOffset == 16)
    }

    @Test("search is case-insensitive")
    func caseInsensitive() {
        let matches = findMatches(in: "Hello HELLO hello", query: "hello")
        #expect(matches.count == 3)
    }

    @Test("search is diacritic-insensitive")
    func diacriticInsensitive() {
        let matches = findMatches(in: "café cafe", query: "cafe")
        #expect(matches.count == 2)
    }

    @Test("match at the very start of document")
    func matchAtStart() {
        let matches = findMatches(in: "swift is great", query: "swift")
        #expect(matches.count == 1)
        #expect(matches[0].characterOffset == 0)
    }

    @Test("match at the very end of document")
    func matchAtEnd() {
        let matches = findMatches(in: "hello world", query: "world")
        #expect(matches.count == 1)
        #expect(matches[0].characterOffset == 6)
        #expect(matches[0].characterOffset + matches[0].matchLength == 11)
    }

    @Test("markdown content with headings and code")
    func markdownContent() {
        let md = "# Swift Guide\n\nSwift is awesome.\n\n```swift\nlet x = 1\n```"
        let matches = findMatches(in: md, query: "swift")
        // "Swift" in heading, "Swift" in paragraph, "swift" in code fence lang hint
        #expect(matches.count == 3)
    }

    // MARK: - scrollFraction(forCharacterOffset:totalLength:)

    @Test("offset 0 returns fraction 0")
    func fractionAtStart() {
        #expect(scrollFraction(forCharacterOffset: 0, totalLength: 1000) == 0)
    }

    @Test("offset equal to totalLength returns fraction 1")
    func fractionAtEnd() {
        #expect(scrollFraction(forCharacterOffset: 1000, totalLength: 1000) == 1)
    }

    @Test("middle offset returns 0.5")
    func fractionAtMiddle() {
        #expect(scrollFraction(forCharacterOffset: 500, totalLength: 1000) == 0.5)
    }

    @Test("offset beyond totalLength is clamped to 1")
    func fractionClamped() {
        #expect(scrollFraction(forCharacterOffset: 2000, totalLength: 1000) == 1)
    }

    @Test("totalLength 0 returns 0 without crash")
    func fractionZeroLength() {
        #expect(scrollFraction(forCharacterOffset: 0, totalLength: 0) == 0)
        #expect(scrollFraction(forCharacterOffset: 5, totalLength: 0) == 0)
    }

    // MARK: - Progressive query refinement (debounce regression)

    @Test("progressive typing narrows results monotonically")
    func progressiveTyping() {
        let text = "searching for search terms in searchable content"
        let q1 = findMatches(in: text, query: "s")
        let q2 = findMatches(in: text, query: "se")
        let q3 = findMatches(in: text, query: "sea")
        let q4 = findMatches(in: text, query: "sear")
        // Each longer query should return equal or fewer matches.
        #expect(q1.count >= q2.count)
        #expect(q2.count >= q3.count)
        #expect(q3.count >= q4.count)
        // The final query "sear" should match "searching", "search", "searchable"
        #expect(q4.count == 3)
    }

    @Test("same query always returns identical results")
    func idempotent() {
        let text = "# Title\n\nSome **bold** text with [links](url) and `code`.\n\n## Another heading"
        let query = "text"
        let run1 = findMatches(in: text, query: query)
        let run2 = findMatches(in: text, query: query)
        #expect(run1 == run2)
    }

    @Test("match length equals query length for ASCII")
    func matchLengthConsistency() {
        let text = "hello world hello swift"
        let query = "hello"
        let matches = findMatches(in: text, query: query)
        for match in matches {
            #expect(match.matchLength == query.count)
        }
    }

}
