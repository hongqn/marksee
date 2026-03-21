import AppKit
import SwiftUI

@MainActor
class AppDelegate: NSObject, NSApplicationDelegate {
    // SwiftUI natively handles opening the first scene (Welcome) on launch or dock click
    // when DocumentGroup is suppressed.

    func applicationShouldOpenUntitledFile(_ sender: NSApplication) -> Bool {
        return false
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Restore the previous session after SwiftUI has finished setting up its scenes.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            self.restoreSession()
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        saveSession()
    }

    // MARK: - Session persistence

    private func saveSession() {
        let paths = NSDocumentController.shared.documents
            .compactMap { $0.fileURL?.path }
        UserDefaults.standard.set(paths, forKey: "sessionDocumentPaths")
    }

    private func restoreSession() {
        let paths = UserDefaults.standard.stringArray(forKey: "sessionDocumentPaths") ?? []
        let urls = paths.compactMap { path -> URL? in
            let url = URL(filePath: path)
            return FileManager.default.fileExists(atPath: path) ? url : nil
        }
        guard !urls.isEmpty else { return }

        let group = DispatchGroup()
        var openedAny = false

        for url in urls {
            group.enter()
            NSDocumentController.shared.openDocument(withContentsOf: url, display: true) { _, _, error in
                if error == nil { openedAny = true }
                group.leave()
            }
        }

        group.notify(queue: .main) {
            guard openedAny else { return }
            // Close the Welcome window now that documents are open.
            for window in NSApp.windows where window.title == "MarkSee" && !(window.delegate is NSDocument) {
                window.close()
            }
        }
    }
}
