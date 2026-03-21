import SwiftUI
import MarkSeeCore
import UniformTypeIdentifiers
import AppKit

@main
struct MarkSeeApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @FocusedValue(\.isShowingFind) private var isShowingFind: Binding<Bool>?
    @FocusedValue(\.printAction) private var printAction: (() -> Void)?

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
        }
        .defaultLaunchBehavior(.suppressed)
        .commands {
            CommandGroup(replacing: .newItem) {}
            CommandGroup(replacing: .printItem) {
                Button("Print…") {
                    printAction?()
                }
                .keyboardShortcut("p", modifiers: .command)
                .disabled(printAction == nil)
            }
            CommandMenu("Find") {
                Button("Find…") {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        isShowingFind?.wrappedValue = true
                    }
                }
                .keyboardShortcut("f", modifiers: .command)
                .disabled(isShowingFind == nil)
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
