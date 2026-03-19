import SwiftUI
import UniformTypeIdentifiers
import AppKit

struct SettingsView: View {
    @State private var isDefault: Bool = false

    var body: some View {
        Form {
            Section {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Default Markdown Viewer")
                        Text(isDefault ? "MarkSee is the default app for .md files" : "MarkSee is not the default app for .md files")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    if isDefault {
                        Label("Active", systemImage: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                            .labelStyle(.iconOnly)
                            .imageScale(.large)
                    } else {
                        Button("Set as Default") {
                            setAsDefaultMarkdownViewer()
                            checkIsDefault()
                        }
                    }
                }
            } header: {
                Text("File Associations")
            }
        }
        .formStyle(.grouped)
        .frame(width: 420)
        .onAppear {
            checkIsDefault()
        }
    }

    private func checkIsDefault() {
        guard let mdType = UTType(filenameExtension: "md"),
              let defaultApp = NSWorkspace.shared.urlForApplication(toOpen: mdType)
        else {
            isDefault = false
            return
        }
        isDefault = defaultApp.standardized == Bundle.main.bundleURL.standardized
    }
}
