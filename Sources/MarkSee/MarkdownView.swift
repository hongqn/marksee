import SwiftUI
import Textual

struct MarkdownView: View {
    let document: MarkdownDocument

    var body: some View {
        ScrollView {
            StructuredText(markdown: document.content)
                .textual.structuredTextStyle(.gitHub)
                .padding(.horizontal, 32)
                .padding(.vertical, 24)
                .frame(maxWidth: 860)
                .frame(maxWidth: .infinity)
        }
        .background(Color(nsColor: .textBackgroundColor))
        .frame(minWidth: 600, minHeight: 400)
    }
}
