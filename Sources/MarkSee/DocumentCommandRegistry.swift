import AppKit
import SwiftUI

@MainActor
final class DocumentCommandRegistry: ObservableObject {
    @Published private(set) var hasActiveDocument = false

    private var activeID: UUID?
    private var findAction: (() -> Void)?
    private var printAction: (() -> Void)?

    func activate(id: UUID, find: @escaping () -> Void, print: @escaping () -> Void) {
        activeID = id
        findAction = find
        printAction = print
        hasActiveDocument = true
    }

    func deactivate(id: UUID) {
        guard activeID == id else { return }
        activeID = nil
        findAction = nil
        printAction = nil
        hasActiveDocument = false
    }

    func showFind() {
        findAction?()
    }

    func printActiveDocument() {
        printAction?()
    }
}

struct DocumentCommandObserver: NSViewRepresentable {
    let onActivate: () -> Void
    let onDeactivate: () -> Void

    func makeNSView(context: Context) -> ObserverView {
        let view = ObserverView()
        view.coordinator = context.coordinator
        return view
    }

    func updateNSView(_ nsView: ObserverView, context: Context) {
        context.coordinator.onActivate = onActivate
        context.coordinator.onDeactivate = onDeactivate
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(onActivate: onActivate, onDeactivate: onDeactivate)
    }

    final class ObserverView: NSView {
        var coordinator: Coordinator?

        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            coordinator?.attach(to: window)
        }
    }

    @MainActor
    final class Coordinator {
        var onActivate: () -> Void
        var onDeactivate: () -> Void

        private weak var observedWindow: NSWindow?
        nonisolated(unsafe) private var tokens: [NSObjectProtocol] = []

        init(onActivate: @escaping () -> Void, onDeactivate: @escaping () -> Void) {
            self.onActivate = onActivate
            self.onDeactivate = onDeactivate
        }

        func attach(to window: NSWindow?) {
            guard observedWindow !== window else { return }
            removeObservers()
            observedWindow = window
            guard let window else { return }

            let center = NotificationCenter.default
            tokens.append(
                center.addObserver(
                    forName: NSWindow.didBecomeKeyNotification,
                    object: window,
                    queue: .main
                ) { [weak self] _ in
                    MainActor.assumeIsolated { self?.onActivate() }
                }
            )
            tokens.append(
                center.addObserver(
                    forName: NSWindow.willCloseNotification,
                    object: window,
                    queue: .main
                ) { [weak self] _ in
                    MainActor.assumeIsolated { self?.onDeactivate() }
                }
            )
            tokens.append(
                center.addObserver(
                    forName: NSWindow.didResignKeyNotification,
                    object: window,
                    queue: .main
                ) { [weak self] _ in
                    MainActor.assumeIsolated { self?.onDeactivate() }
                }
            )

            DispatchQueue.main.async { [weak self, weak window] in
                guard let self, let window, window.isKeyWindow || window.isMainWindow else { return }
                self.onActivate()
            }
        }

        private func removeObservers() {
            tokens.forEach { NotificationCenter.default.removeObserver($0) }
            tokens.removeAll()
        }

        deinit {
            tokens.forEach { NotificationCenter.default.removeObserver($0) }
        }
    }
}
