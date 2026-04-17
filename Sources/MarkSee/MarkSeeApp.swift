import SwiftUI
import MarkSeeCore
import UniformTypeIdentifiers
import AppKit

@main
struct MarkSeeApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var documentCommands = DocumentCommandRegistry()

    var body: some Scene {
        WindowGroup(id: "welcome") {
            WelcomeView {
                for window in NSApp.windows where window.title == "MarkSee" && !(window.delegate is NSDocument) {
                    window.close()
                }
            }
        }
        .windowStyle(.hiddenTitleBar)
        .defaultLaunchBehavior(.presented)

        DocumentGroup(viewing: MarkdownDocument.self) { file in
            MarkdownView(document: file.document, fileURL: file.fileURL)
                .navigationTitle(file.fileURL?.deletingPathExtension().lastPathComponent ?? "")
                .environmentObject(documentCommands)
        }
        .defaultLaunchBehavior(.suppressed)
        .commands {
            CommandGroup(replacing: .newItem) {}
            CommandGroup(replacing: .printItem) {
                Button("Print…") {
                    documentCommands.printActiveDocument()
                }
                .keyboardShortcut("p", modifiers: .command)
                .disabled(!documentCommands.hasActiveDocument)
            }
            CommandMenu("Find") {
                Button("Find…") {
                    documentCommands.showFind()
                }
                .keyboardShortcut("f", modifiers: .command)
                .disabled(!documentCommands.hasActiveDocument)
            }
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
