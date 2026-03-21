import SwiftUI

struct FindBar: View {
    @Binding var query: String
    let matchCount: Int
    /// 0-based index of the currently selected match.
    let currentMatchIndex: Int
    let onNext: () -> Void
    let onPrevious: () -> Void
    let onDismiss: () -> Void

    @FocusState private var isTextFieldFocused: Bool

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)

            TextField("Find", text: $query)
                .textFieldStyle(.plain)
                .focused($isTextFieldFocused)
                .onSubmit { onNext() }
                .frame(minWidth: 160)

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
        .overlay(alignment: .bottom) {
            Divider()
        }
        .onAppear { isTextFieldFocused = true }
    }

    @ViewBuilder
    private var matchLabel: some View {
        if query.isEmpty {
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
