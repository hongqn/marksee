import SwiftUI

struct FindBar: View {
    @State private var text = ""
    @State private var debounceTask: Task<Void, Never>?
    /// Tracks the last query published to the parent so the match label
    /// can hide stale results while a debounce is pending.
    @State private var publishedQuery = ""

    let matchCount: Int
    /// 0-based index of the currently selected match.
    let currentMatchIndex: Int
    /// Called with the debounced query (or "" when cleared).
    let onQueryChange: (String) -> Void
    let onNext: () -> Void
    let onPrevious: () -> Void
    let onDismiss: () -> Void

    @FocusState private var isTextFieldFocused: Bool

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)

            TextField("Find", text: $text)
                .textFieldStyle(.plain)
                .focused($isTextFieldFocused)
                .onSubmit { onNext() }
                .frame(minWidth: 160)
                .accessibilityIdentifier("findField")

            matchLabel
                .frame(minWidth: 70, alignment: .leading)

            Divider().frame(height: 16)

            Button(action: onPrevious) {
                Image(systemName: "chevron.up")
            }
            .help("Previous Match (⇧↩)")
            .accessibilityLabel("Previous Match")
            .disabled(matchCount == 0)
            .buttonStyle(.plain)

            Button(action: onNext) {
                Image(systemName: "chevron.down")
            }
            .help("Next Match (↩)")
            .accessibilityLabel("Next Match")
            .disabled(matchCount == 0)
            .buttonStyle(.plain)

            Divider().frame(height: 16)

            Button(action: onDismiss) {
                Image(systemName: "xmark")
            }
            .help("Close Find Bar (⎋)")
            .accessibilityLabel("Close Find Bar")
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .background(.bar)
        .accessibilityIdentifier("findBar")
        .overlay(alignment: .bottom) {
            Divider()
        }
        .onAppear {
            DispatchQueue.main.async {
                isTextFieldFocused = true
            }
        }
        .onDisappear { debounceTask?.cancel() }
        .onChange(of: text) { _, newText in
            debounceTask?.cancel()
            if newText.isEmpty {
                publishedQuery = ""
                onQueryChange("")
            } else {
                debounceTask = Task {
                    try? await Task.sleep(for: .milliseconds(300))
                    guard !Task.isCancelled else { return }
                    publishedQuery = newText
                    onQueryChange(newText)
                }
            }
        }
    }

    @ViewBuilder
    private var matchLabel: some View {
        if text.isEmpty || text != publishedQuery {
            EmptyView()
        } else if matchCount == 0 {
            Text("No results")
                .foregroundStyle(.red)
                .font(.callout)
        } else {
            Text("\(currentMatchIndex + 1) of \(matchCount)")
                .foregroundStyle(.secondary)
                .font(.callout)
                .monospacedDigit()
                .accessibilityLabel("Match \(currentMatchIndex + 1) of \(matchCount)")
        }
    }
}

/// Key for propagating the find-bar visibility binding from MarkdownView to app commands.
struct FindVisibilityKey: FocusedValueKey {
    typealias Value = Binding<Bool>
}

/// Key for propagating the print action from MarkdownView to app commands.
struct PrintActionKey: FocusedValueKey {
    typealias Value = () -> Void
}

extension FocusedValues {
    var isShowingFind: Binding<Bool>? {
        get { self[FindVisibilityKey.self] }
        set { self[FindVisibilityKey.self] = newValue }
    }

    var printAction: (() -> Void)? {
        get { self[PrintActionKey.self] }
        set { self[PrintActionKey.self] = newValue }
    }
}
