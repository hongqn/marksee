import AppKit
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    var welcomeWindow: NSWindow?

    func applicationShouldOpenUntitledFile(_ sender: NSApplication) -> Bool {
        Task { @MainActor in showWelcomeWindow() }
        return false
    }

    @MainActor
    func showWelcomeWindow() {
        if welcomeWindow == nil {
            let view = WelcomeView {
                self.welcomeWindow?.orderOut(nil)
            }
            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 720, height: 440),
                styleMask: [.titled, .closable, .miniaturizable],
                backing: .buffered,
                defer: false
            )
            window.title = "MarkSee"
            window.titlebarAppearsTransparent = true
            window.contentView = NSHostingView(rootView: view)
            window.center()
            window.isReleasedWhenClosed = false
            welcomeWindow = window
        }
        welcomeWindow?.makeKeyAndOrderFront(nil)
    }
}
