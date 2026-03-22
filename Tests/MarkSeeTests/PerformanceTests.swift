import Testing
import Foundation
@testable import MarkSeeCore

// Synthetic Markdown generator — produces realistic-looking documents of a
// given size so we can benchmark on consistent, reproducible inputs.
private func syntheticMarkdown(paragraphs: Int) -> String {
    var lines: [String] = []
    let words = ["the", "quick", "brown", "fox", "jumps", "over", "lazy", "dog",
                 "Swift", "macOS", "Markdown", "rendering", "performance", "test"]
    var rng = SystemRandomNumberGenerator()
    for i in 0..<paragraphs {
        // Insert a heading every 10 paragraphs.
        if i % 10 == 0 {
            let level = (i / 10) % 3 + 1
            lines.append(String(repeating: "#", count: level) + " Section \(i / 10 + 1)")
        }
        // Body paragraph: ~15 words.
        let body = (0..<15).map { _ in words[Int(rng.next() % UInt64(words.count))] }.joined(separator: " ")
        lines.append(body)
        lines.append("")
    }
    return lines.joined(separator: "\n")
}

@Suite("Performance")
struct PerformanceTests {

    // MARK: - Document parsing (UTF-8 decode)

    @Test("parse 10 KB document")
    func parse10KB() throws {
        let content = syntheticMarkdown(paragraphs: 100)   // ~3 KB typical
        let data = try #require(content.data(using: .utf8))
        let clock = ContinuousClock()
        var elapsed: [Duration] = []
        for _ in 0..<200 {
            let start = clock.now
            _ = try MarkdownDocument(utf8Data: data)
            elapsed.append(clock.now - start)
        }
        let median = elapsed.sorted()[elapsed.count / 2]
        print("parse ~\(data.count / 1024) KB — median \(median)")
    }

    @Test("parse 100 KB document")
    func parse100KB() throws {
        let content = syntheticMarkdown(paragraphs: 1_000)
        let data = try #require(content.data(using: .utf8))
        let clock = ContinuousClock()
        var elapsed: [Duration] = []
        for _ in 0..<100 {
            let start = clock.now
            _ = try MarkdownDocument(utf8Data: data)
            elapsed.append(clock.now - start)
        }
        let median = elapsed.sorted()[elapsed.count / 2]
        print("parse ~\(data.count / 1024) KB — median \(median)")
    }

    @Test("parse 1 MB document")
    func parse1MB() throws {
        let content = syntheticMarkdown(paragraphs: 10_000)
        let data = try #require(content.data(using: .utf8))
        let clock = ContinuousClock()
        var elapsed: [Duration] = []
        for _ in 0..<20 {
            let start = clock.now
            _ = try MarkdownDocument(utf8Data: data)
            elapsed.append(clock.now - start)
        }
        let median = elapsed.sorted()[elapsed.count / 2]
        print("parse ~\(data.count / 1024) KB — median \(median)")
    }

    // MARK: - Search

    @Test("search 10 KB document")
    func search10KB() throws {
        let content = syntheticMarkdown(paragraphs: 100)
        let clock = ContinuousClock()
        var elapsed: [Duration] = []
        for _ in 0..<500 {
            let start = clock.now
            _ = findMatches(in: content, query: "swift")
            elapsed.append(clock.now - start)
        }
        let median = elapsed.sorted()[elapsed.count / 2]
        print("search ~\(content.utf8.count / 1024) KB — median \(median)")
    }

    @Test("search 100 KB document")
    func search100KB() throws {
        let content = syntheticMarkdown(paragraphs: 1_000)
        let clock = ContinuousClock()
        var elapsed: [Duration] = []
        for _ in 0..<200 {
            let start = clock.now
            _ = findMatches(in: content, query: "swift")
            elapsed.append(clock.now - start)
        }
        let median = elapsed.sorted()[elapsed.count / 2]
        print("search ~\(content.utf8.count / 1024) KB — median \(median)")
    }

    @Test("search 1 MB document")
    func search1MB() throws {
        let content = syntheticMarkdown(paragraphs: 10_000)
        let clock = ContinuousClock()
        var elapsed: [Duration] = []
        for _ in 0..<50 {
            let start = clock.now
            _ = findMatches(in: content, query: "swift")
            elapsed.append(clock.now - start)
        }
        let median = elapsed.sorted()[elapsed.count / 2]
        print("search ~\(content.utf8.count / 1024) KB — median \(median)")
    }

    // MARK: - Heading extraction

    @Test("extract headings 100 KB document")
    func extractHeadings100KB() throws {
        let content = syntheticMarkdown(paragraphs: 1_000)
        let clock = ContinuousClock()
        var elapsed: [Duration] = []
        for _ in 0..<200 {
            let start = clock.now
            _ = extractHeadings(from: content)
            elapsed.append(clock.now - start)
        }
        let median = elapsed.sorted()[elapsed.count / 2]
        let headingCount = extractHeadings(from: content).count
        print("extractHeadings \(headingCount) headings in ~\(content.utf8.count / 1024) KB — median \(median)")
    }
}
