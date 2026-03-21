import Testing
@testable import MarkSeeCore

@Suite("MarkdownHeadings")
struct MarkdownHeadingsTests {

    // MARK: - Basic level detection

    @Test("H1 through H6 levels are parsed correctly")
    func allLevels() {
        let md = "# One\n## Two\n### Three\n#### Four\n##### Five\n###### Six"
        let headings = extractHeadings(from: md)
        #expect(headings.map(\.level) == [1, 2, 3, 4, 5, 6])
        #expect(headings.map(\.title) == ["One", "Two", "Three", "Four", "Five", "Six"])
    }

    @Test("more than 6 hashes is not a heading")
    func sevenHashes() {
        let headings = extractHeadings(from: "####### Not a heading")
        #expect(headings.isEmpty)
    }

    @Test("no space after # is not a heading")
    func noSpaceAfterHash() {
        let headings = extractHeadings(from: "#NoSpace")
        #expect(headings.isEmpty)
    }

    @Test("lone # with no text is an empty H1")
    func loneHash() {
        let headings = extractHeadings(from: "#")
        #expect(headings.count == 1)
        #expect(headings[0].level == 1)
        #expect(headings[0].title == "")
    }

    // MARK: - Title content

    @Test("trailing # closing markers are stripped")
    func closingMarkers() {
        let headings = extractHeadings(from: "## Title ##")
        #expect(headings[0].title == "Title")
    }

    @Test("inline bold is stripped")
    func inlineBold() {
        let headings = extractHeadings(from: "## **Bold** Title")
        #expect(headings[0].title == "Bold Title")
    }

    @Test("inline code is stripped")
    func inlineCode() {
        let headings = extractHeadings(from: "## Use `foo()` here")
        #expect(headings[0].title == "Use foo() here")
    }

    @Test("inline link text is kept, URL is dropped")
    func inlineLink() {
        let headings = extractHeadings(from: "## [Click here](https://example.com)")
        #expect(headings[0].title == "Click here")
    }

    // MARK: - Character offsets

    @Test("first heading has offset 0")
    func firstHeadingOffset() {
        let headings = extractHeadings(from: "# Hello")
        #expect(headings[0].characterOffset == 0)
    }

    @Test("second heading offset reflects preceding text length")
    func secondHeadingOffset() {
        let first = "# First\n"
        let md = first + "## Second"
        let headings = extractHeadings(from: md)
        #expect(headings.count == 2)
        #expect(headings[1].characterOffset == first.count)
    }

    // MARK: - Code fence skipping

    @Test("headings inside fenced code blocks are ignored")
    func headingsInsideCodeFence() {
        let md = """
        # Real Heading

        ```
        # Fake heading inside code
        ```

        ## Another Real Heading
        """
        let headings = extractHeadings(from: md)
        #expect(headings.count == 2)
        #expect(headings[0].title == "Real Heading")
        #expect(headings[1].title == "Another Real Heading")
    }

    @Test("tilde code fence is also respected")
    func tildeCodeFence() {
        let md = "~~~\n# Inside tilde fence\n~~~\n# Outside"
        let headings = extractHeadings(from: md)
        #expect(headings.count == 1)
        #expect(headings[0].title == "Outside")
    }

    // MARK: - Empty input

    @Test("empty document returns no headings")
    func emptyDocument() {
        #expect(extractHeadings(from: "").isEmpty)
    }

    @Test("document with no headings returns empty array")
    func noHeadings() {
        let md = "Just some plain text.\n\nAnother paragraph."
        #expect(extractHeadings(from: md).isEmpty)
    }
}
