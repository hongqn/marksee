import Foundation

@Observable
@MainActor
final class FileWatcher {
    var content: String = ""

    private var source: DispatchSourceFileSystemObject?
    private var fileDescriptor: Int32 = -1
    private var watchedURL: URL?

    func watch(url: URL, initialContent: String) {
        content = initialContent
        watchedURL = url
        startSource(url: url)
    }

    func stop() {
        source?.cancel()
        source = nil
    }

    private func startSource(url: URL) {
        source?.cancel()

        let fd = open(url.path, O_EVTONLY)
        guard fd >= 0 else { return }
        fileDescriptor = fd

        let src = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fd,
            eventMask: [.write, .rename, .delete],
            queue: .main
        )

        src.setEventHandler { [weak self] in
            guard let self else { return }
            let flags = src.data
            if flags.contains(.rename) || flags.contains(.delete) {
                // File was replaced atomically (e.g. most editors); re-open
                self.source?.cancel()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    if let u = self.watchedURL { self.startSource(url: u) }
                }
            }
            self.reload()
        }

        src.setCancelHandler {
            close(fd)
        }

        src.resume()
        source = src
    }

    private func reload() {
        guard let url = watchedURL,
              let text = try? String(contentsOf: url, encoding: .utf8)
        else { return }
        content = text
    }

    nonisolated func cleanup() {
        // source is cancelled via stop() before dealloc
    }
}
