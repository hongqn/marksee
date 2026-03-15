import SwiftUI
import UniformTypeIdentifiers

struct MarkdownDocument: FileDocument {
    var content: String

    static var readableContentTypes: [UTType] {
        [UTType(importedAs: "net.daringfireball.markdown")]
    }

    init(content: String = "") {
        self.content = content
    }

    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents,
              let string = String(data: data, encoding: .utf8)
        else {
            throw CocoaError(.fileReadCorruptFile)
        }
        content = string
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let data = content.data(using: .utf8) ?? Data()
        return FileWrapper(regularFileWithContents: data)
    }
}
