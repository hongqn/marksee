import SwiftUI
import MarkSeeCore

struct TOCSidebar: View {
    let headings: [MarkdownHeading]
    let onSelect: (MarkdownHeading) -> Void

    var body: some View {
        List(headings, id: \.characterOffset) { heading in
            Button {
                onSelect(heading)
            } label: {
                Text(heading.title)
                    .lineLimit(1)
                    .font(font(for: heading.level))
                    .foregroundStyle(heading.level == 1 ? .primary : .secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading, CGFloat(heading.level - 1) * 12)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(heading.title)
            .accessibilityHint("Heading level \(heading.level). Tap to scroll to this section.")
        }
        .listStyle(.sidebar)
        .frame(minWidth: 180, maxWidth: 260)
    }

    private func font(for level: Int) -> Font {
        switch level {
        case 1: return .headline
        case 2: return .subheadline
        default: return .caption
        }
    }
}
