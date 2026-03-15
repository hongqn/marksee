import Testing
import UniformTypeIdentifiers
@testable import MarkSeeCore

@Suite("MarkdownDocument")
struct MarkdownDocumentTests {

    // MARK: - init(content:)

    @Test("default content is empty string")
    func defaultContent() {
        let doc = MarkdownDocument()
        #expect(doc.content == "")
    }

    @Test("stores provided content")
    func initWithContent() {
        let doc = MarkdownDocument(content: "# Hello")
        #expect(doc.content == "# Hello")
    }

    // MARK: - readableContentTypes

    @Test("readableContentTypes includes the Markdown UTType")
    func readableContentTypes() {
        let types = MarkdownDocument.readableContentTypes
        #expect(types.contains(UTType(importedAs: "net.daringfireball.markdown")))
    }

    // MARK: - init(utf8Data:)

    @Test("reads valid UTF-8 data", arguments: [
        "",
        "# Hello",
        "Hello\nWorld\n",
        "Unicode: 🎉",
    ])
    func readValidData(content: String) throws {
        let data = try #require(content.data(using: .utf8))
        let doc = try MarkdownDocument(utf8Data: data)
        #expect(doc.content == content)
    }

    @Test("throws fileReadCorruptFile for non-UTF-8 bytes")
    func readInvalidUTF8Throws() {
        let invalidData = Data([0xFF, 0xFE, 0x00])
        #expect {
            try MarkdownDocument(utf8Data: invalidData)
        } throws: { error in
            (error as? CocoaError)?.code == .fileReadCorruptFile
        }
    }

    // MARK: - utf8Data()

    @Test("utf8Data encodes content as UTF-8", arguments: [
        "",
        "# Title",
        "Line 1\nLine 2\n",
        "Unicode: 🌍",
    ])
    func utf8DataEncoding(content: String) throws {
        let doc = MarkdownDocument(content: content)
        let data = try doc.utf8Data()
        let decoded = try #require(String(data: data, encoding: .utf8))
        #expect(decoded == content)
    }

    // MARK: - Roundtrip

    @Test("roundtrip: utf8Data → init(utf8Data:) restores original content", arguments: [
        "",
        "# Title",
        "Line 1\nLine 2\n",
        "Unicode: 🌍",
    ])
    func roundtrip(content: String) throws {
        let original = MarkdownDocument(content: content)
        let data = try original.utf8Data()
        let restored = try MarkdownDocument(utf8Data: data)
        #expect(restored.content == content)
    }
}
