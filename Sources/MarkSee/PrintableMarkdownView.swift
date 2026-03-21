import SwiftUI
import Textual

/// A print-optimized markdown view without toolbar, sidebar, or find bar.
/// Rendered at full width so NSPrintOperation can paginate it vertically.
struct PrintableMarkdownView: View {
    let content: String

    var body: some View {
        StructuredText(markdown: content)
            .textual.structuredTextStyle(.gitHub)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 8)
            .padding(.vertical, 16)
            .background(Color.white)
    }
}
