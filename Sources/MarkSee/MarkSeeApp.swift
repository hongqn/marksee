import SwiftUI

@main
struct MarkSeeApp: App {
    var body: some Scene {
        DocumentGroup(viewing: MarkdownDocument.self) { file in
            MarkdownView(document: file.document)
                .navigationTitle(file.fileURL?.deletingPathExtension().lastPathComponent ?? "")
        }
        .commands {
            CommandGroup(replacing: .newItem) {}
        }
    }
}
