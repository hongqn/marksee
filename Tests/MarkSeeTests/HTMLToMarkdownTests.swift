import Testing
@testable import MarkSeeCore

@Suite("HTMLToMarkdown")
struct HTMLToMarkdownTests {

    // MARK: - Headings

    @Test("h1 through h6 produce correct marker count", arguments: [
        ("<h1>Title</h1>", "# Title"),
        ("<h2>Title</h2>", "## Title"),
        ("<h3>Title</h3>", "### Title"),
        ("<h4>Title</h4>", "#### Title"),
        ("<h5>Title</h5>", "##### Title"),
        ("<h6>Title</h6>", "###### Title"),
    ])
    func headings(input: String, expected: String) {
        #expect(htmlToMarkdown(input) == expected)
    }

    // MARK: - Paragraphs

    @Test("single paragraph")
    func singleParagraph() {
        #expect(htmlToMarkdown("<p>Hello world</p>") == "Hello world")
    }

    @Test("two paragraphs separated by blank line")
    func twoParagraphs() {
        let html = "<p>First</p><p>Second</p>"
        #expect(htmlToMarkdown(html) == "First\n\nSecond")
    }

    // MARK: - Inline formatting

    @Test("bold with strong tag")
    func boldStrong() {
        #expect(htmlToMarkdown("<strong>bold</strong>") == "**bold**")
    }

    @Test("bold with b tag")
    func boldB() {
        #expect(htmlToMarkdown("<b>bold</b>") == "**bold**")
    }

    @Test("italic with em tag")
    func italicEm() {
        #expect(htmlToMarkdown("<em>italic</em>") == "*italic*")
    }

    @Test("italic with i tag")
    func italicI() {
        #expect(htmlToMarkdown("<i>italic</i>") == "*italic*")
    }

    @Test("bold and italic combined")
    func boldItalic() {
        let html = "<strong><em>both</em></strong>"
        #expect(htmlToMarkdown(html) == "***both***")
    }

    @Test("strikethrough")
    func strikethrough() {
        #expect(htmlToMarkdown("<s>struck</s>") == "~~struck~~")
    }

    @Test("inline code")
    func inlineCode() {
        #expect(htmlToMarkdown("<code>print()</code>") == "`print()`")
    }

    // MARK: - Links

    @Test("link with href")
    func link() {
        let html = #"<a href="https://example.com">Example</a>"#
        #expect(htmlToMarkdown(html) == "[Example](https://example.com)")
    }

    @Test("link with no href")
    func linkNoHref() {
        #expect(htmlToMarkdown("<a>bare</a>") == "[bare]()")
    }

    // MARK: - Code blocks

    @Test("fenced code block from pre/code")
    func codeBlock() {
        let html = "<pre><code>let x = 1\nlet y = 2\n</code></pre>"
        #expect(htmlToMarkdown(html) == "```\nlet x = 1\nlet y = 2\n```")
    }

    @Test("fenced code block without trailing newline in source")
    func codeBlockNoTrailingNewline() {
        let html = "<pre><code>hello</code></pre>"
        #expect(htmlToMarkdown(html) == "```\nhello\n```")
    }

    // MARK: - Lists

    @Test("unordered list")
    func unorderedList() {
        let html = "<ul><li>Apple</li><li>Banana</li></ul>"
        #expect(htmlToMarkdown(html) == "- Apple\n- Banana")
    }

    @Test("ordered list")
    func orderedList() {
        let html = "<ol><li>First</li><li>Second</li></ol>"
        #expect(htmlToMarkdown(html) == "1. First\n2. Second")
    }

    @Test("nested unordered list")
    func nestedList() {
        let html = "<ul><li>Parent<ul><li>Child</li></ul></li></ul>"
        let result = htmlToMarkdown(html)
        #expect(result.contains("- Parent"))
        #expect(result.contains("  - Child"))
    }

    // MARK: - Blockquotes

    @Test("single-level blockquote")
    func blockquote() {
        let html = "<blockquote><p>Quoted text</p></blockquote>"
        let result = htmlToMarkdown(html)
        #expect(result.contains("> Quoted text"))
    }

    // MARK: - Horizontal rule

    @Test("hr produces --- separator")
    func horizontalRule() {
        let result = htmlToMarkdown("<p>Before</p><hr/><p>After</p>")
        #expect(result.contains("---"))
        #expect(result.contains("Before"))
        #expect(result.contains("After"))
    }

    // MARK: - HTML entities

    @Test("HTML entities are decoded", arguments: [
        ("&amp;",   "&"),
        ("&lt;",    "<"),
        ("&gt;",    ">"),
        ("&quot;",  "\""),
        ("&#39;",   "'"),
    ])
    func htmlEntities(entity: String, expected: String) {
        #expect(htmlToMarkdown(entity) == expected)
    }

    @Test("non-breaking space preserved between words")
    func nbspBetweenWords() {
        #expect(htmlToMarkdown("<p>a&nbsp;b</p>") == "a b")
    }

    @Test("numeric HTML entity")
    func numericEntity() {
        #expect(htmlToMarkdown("&#65;") == "A")
    }

    // MARK: - Mixed content

    @Test("heading followed by paragraph")
    func headingAndParagraph() {
        let html = "<h1>Title</h1><p>Body text here.</p>"
        let result = htmlToMarkdown(html)
        #expect(result == "# Title\n\nBody text here.")
    }

    @Test("paragraph with bold and link")
    func mixedInline() {
        let html = #"<p>See <strong>this</strong> <a href="https://example.com">link</a>.</p>"#
        #expect(htmlToMarkdown(html) == "See **this** [link](https://example.com).")
    }

    @Test("empty input returns empty string")
    func emptyInput() {
        #expect(htmlToMarkdown("") == "")
    }

    @Test("plain text with no tags passes through")
    func plainText() {
        #expect(htmlToMarkdown("Hello, world!") == "Hello, world!")
    }
}
