import SwiftUI
import UniformTypeIdentifiers

public struct MarkdownDocument: FileDocument {
    public var content: String

    public static var readableContentTypes: [UTType] {
        [UTType(importedAs: "net.daringfireball.markdown")]
    }

    public init(content: String = "") {
        self.content = content
    }

    public init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents else {
            throw CocoaError(.fileReadCorruptFile)
        }
        try self.init(utf8Data: data)
    }

    public func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: try utf8Data())
    }

    // MARK: - Internal helpers (exposed for testing)

    init(utf8Data data: Data) throws {
        guard let string = String(data: data, encoding: .utf8) else {
            throw CocoaError(.fileReadCorruptFile)
        }
        content = string
    }

    func utf8Data() throws -> Data {
        guard let data = content.data(using: .utf8) else {
            throw CocoaError(.fileWriteUnknown)
        }
        return data
    }
}
