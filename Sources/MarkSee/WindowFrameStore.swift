import AppKit

/// Persists document window frames (size + position) to UserDefaults.
///
/// - Per-document frames are keyed by the file path under `"windowFrames"`.
/// - `lastFrame` is a single fallback used when no per-document frame exists yet.
enum WindowFrameStore {

    private static let perDocumentKey = "windowFrames"
    private static let lastFrameKey = "lastWindowFrame"

    // MARK: Per-document

    static func frame(for url: URL) -> NSRect? {
        let dict = UserDefaults.standard.dictionary(forKey: perDocumentKey) ?? [:]
        guard let values = dict[url.path] as? [Double], values.count == 4 else { return nil }
        return NSRect(x: values[0], y: values[1], width: values[2], height: values[3])
    }

    static func setFrame(_ frame: NSRect, for url: URL) {
        var dict = UserDefaults.standard.dictionary(forKey: perDocumentKey) ?? [:]
        dict[url.path] = [frame.origin.x, frame.origin.y, frame.width, frame.height]
        UserDefaults.standard.set(dict, forKey: perDocumentKey)
    }

    // MARK: Last-used fallback

    static var lastFrame: NSRect? {
        guard let values = UserDefaults.standard.array(forKey: lastFrameKey) as? [Double],
              values.count == 4 else { return nil }
        return NSRect(x: values[0], y: values[1], width: values[2], height: values[3])
    }

    static func setLastFrame(_ frame: NSRect) {
        UserDefaults.standard.set(
            [frame.origin.x, frame.origin.y, frame.width, frame.height],
            forKey: lastFrameKey
        )
    }
}
