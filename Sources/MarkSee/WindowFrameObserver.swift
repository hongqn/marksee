import AppKit
import SwiftUI

/// Invisible background view that restores and persists the enclosing document window's
/// frame (size + position) via `WindowFrameStore`.
///
/// Attach with `.background(WindowFrameObserver(fileURL: fileURL))`.
struct WindowFrameObserver: NSViewRepresentable {
    let fileURL: URL?

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        // Window is not yet available at makeNSView time; defer to next run-loop turn.
        DispatchQueue.main.async {
            context.coordinator.attach(to: view.window, fileURL: fileURL)
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator() }

    // MARK: -

    @MainActor
    final class Coordinator {
        private(set) var fileURL: URL?
        // nonisolated(unsafe) lets deinit (which is nonisolated) release the tokens.
        // Safe because all writes happen on the main actor.
        nonisolated(unsafe) private var tokens: [NSObjectProtocol] = []

        func attach(to window: NSWindow?, fileURL: URL?) {
            guard let window else { return }
            self.fileURL = fileURL

            applyFrame(to: window)

            let center = NotificationCenter.default
            tokens.append(
                center.addObserver(
                    forName: NSWindow.didMoveNotification,
                    object: window, queue: .main
                ) { [weak self] _ in
                    MainActor.assumeIsolated { self?.save(window) }
                }
            )
            tokens.append(
                center.addObserver(
                    forName: NSWindow.didResizeNotification,
                    object: window, queue: .main
                ) { [weak self] _ in
                    MainActor.assumeIsolated { self?.save(window) }
                }
            )
        }

        private func applyFrame(to window: NSWindow) {
            let saved: NSRect?
            if let url = fileURL {
                saved = WindowFrameStore.frame(for: url) ?? WindowFrameStore.lastFrame
            } else {
                saved = WindowFrameStore.lastFrame
            }
            guard let frame = saved else { return }

            // Validate the frame is on a live screen before applying.
            let onScreen = NSScreen.screens.contains { NSIntersectsRect($0.visibleFrame, frame) }
            guard onScreen else { return }

            window.setFrame(frame, display: false)
        }

        private func save(_ window: NSWindow) {
            let frame = window.frame
            WindowFrameStore.setLastFrame(frame)
            if let url = fileURL {
                WindowFrameStore.setFrame(frame, for: url)
            }
        }

        deinit {
            tokens.forEach { NotificationCenter.default.removeObserver($0) }
        }
    }
}
