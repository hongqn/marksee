import SwiftUI
import UniformTypeIdentifiers
import AppKit

/// User-selectable display theme.
enum MarkSeeTheme: String, CaseIterable, Identifiable {
    case system
    case light
    case dark

    var id: String { rawValue }

    var label: String {
        switch self {
        case .system: return "System"
        case .light:  return "GitHub Light"
        case .dark:   return "GitHub Dark"
        }
    }

    /// The SwiftUI color scheme override, or `nil` to follow the system setting.
    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light:  return .light
        case .dark:   return .dark
        }
    }
}

struct SettingsView: View {
    @State private var isDefault: Bool = false
    @AppStorage("theme") private var themeRawValue: String = MarkSeeTheme.system.rawValue

    private var selectedTheme: Binding<MarkSeeTheme> {
        Binding(
            get: { MarkSeeTheme(rawValue: themeRawValue) ?? .system },
            set: { themeRawValue = $0.rawValue }
        )
    }

    var body: some View {
        Form {
            Section {
                Picker("Theme", selection: selectedTheme) {
                    ForEach(MarkSeeTheme.allCases) { theme in
                        Text(theme.label).tag(theme)
                    }
                }
                .pickerStyle(.segmented)
            } header: {
                Text("Appearance")
            }

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
