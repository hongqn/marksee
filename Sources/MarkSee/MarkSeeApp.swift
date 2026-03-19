import SwiftUI
import MarkSeeCore
import UniformTypeIdentifiers
import AppKit

@main
struct MarkSeeApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    var body: some Scene {
        DocumentGroup(viewing: MarkdownDocument.self) { file in
            MarkdownView(document: file.document, fileURL: file.fileURL)
                .navigationTitle(file.fileURL?.deletingPathExtension().lastPathComponent ?? "")
        }
        .commands {
            CommandGroup(replacing: .newItem) {}
        }

        Settings {
            SettingsView()
        }
    }
}

func setAsDefaultMarkdownViewer() {
    let appURL = Bundle.main.bundleURL
    for ext in ["md", "markdown"] {
        guard let type = UTType(filenameExtension: ext) else { continue }
        NSWorkspace.shared.setDefaultApplication(at: appURL, toOpen: type) { _ in }
    }
}
