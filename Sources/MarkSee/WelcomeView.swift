import SwiftUI
import UniformTypeIdentifiers
import AppKit

struct WelcomeView: View {
    let onOpenFile: () -> Void

    @State private var recentURLs: [URL] = []
    @State private var hoveredURL: URL?

    var body: some View {
        HStack(spacing: 0) {
            leftPanel
                .frame(width: 240)
                .padding(32)

            Divider()

            rightPanel
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(width: 720, height: 440)
        .onAppear { reloadRecentURLs() }
        .onReceive(NotificationCenter.default.publisher(for: UserDefaults.didChangeNotification)) { _ in
            reloadRecentURLs()
        }
    }

    private func reloadRecentURLs() {
        let paths = UserDefaults.standard.stringArray(forKey: "recentDocumentPaths") ?? []
        recentURLs = paths
            .compactMap { URL(fileURLWithPath: $0) }
            .filter { FileManager.default.fileExists(atPath: $0.path) }
    }

    private var leftPanel: some View {
        VStack(alignment: .leading, spacing: 0) {
            Spacer()

            if let icon = NSImage(named: NSImage.applicationIconName) {
                Image(nsImage: icon)
                    .resizable()
                    .frame(width: 80, height: 80)
                    .accessibilityHidden(true)
            }

            Text("MarkSee")
                .font(.title2)
                .fontWeight(.semibold)
                .padding(.top, 10)

            if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
                Text("Version \(version)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.top, 2)
            }

            Spacer()

            Divider()
                .padding(.vertical, 16)

            Button(action: runOpenPanel) {
                Label("Open existing document…", systemImage: "folder")
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)

            Spacer()
        }
    }

    private var rightPanel: some View {
        Group {
            if recentURLs.isEmpty {
                VStack {
                    Spacer()
                    Text("No Recent Documents")
                        .foregroundStyle(.tertiary)
                    Spacer()
                }
                .frame(maxWidth: .infinity)
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        ForEach(recentURLs, id: \.self) { url in
                            recentFileRow(url: url)
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
        }
    }

    private func recentFileRow(url: URL) -> some View {
        Button {
            open(url)
        } label: {
            HStack(spacing: 12) {
                Image(nsImage: NSWorkspace.shared.icon(forFile: url.path))
                    .resizable()
                    .frame(width: 32, height: 32)

                VStack(alignment: .leading, spacing: 2) {
                    Text(url.deletingPathExtension().lastPathComponent)
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                    Text(url.deletingLastPathComponent().path
                            .replacingOccurrences(of: NSHomeDirectory(), with: "~"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(hoveredURL == url ? Color.secondary.opacity(0.15) : Color.clear)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(url.deletingPathExtension().lastPathComponent)
        .accessibilityHint(url.deletingLastPathComponent().path
            .replacingOccurrences(of: NSHomeDirectory(), with: "~"))
        .onHover { hovered in
            hoveredURL = hovered ? url : nil
        }
    }

    private func runOpenPanel() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [UTType(filenameExtension: "md"),
                                     UTType(filenameExtension: "markdown")]
            .compactMap { $0 }
        panel.allowsMultipleSelection = false
        guard panel.runModal() == .OK, let url = panel.url else { return }
        open(url)
    }

    private func open(_ url: URL) {
        noteRecentDocument(url)
        NSDocumentController.shared.openDocument(withContentsOf: url, display: true) { _, _, _ in
            DispatchQueue.main.async { onOpenFile() }
        }
    }
}
