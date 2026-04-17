import Foundation
import JavaScriptCore

struct CodeSyntaxToken: Hashable, Sendable {
    let content: String
    let type: String
}

actor CodeSyntaxTokenizer {
    static let shared = CodeSyntaxTokenizer()

    private let context: JSContext?

    init() {
        guard let context = JSContext(),
              let scriptURL = Self.prismBundleURL(),
              let script = try? String(contentsOf: scriptURL, encoding: .utf8) else {
            self.context = nil
            return
        }

        context.evaluateScript(script)
        self.context = context
    }

    func tokenize(code: String, language: String?) -> [CodeSyntaxToken] {
        guard let language,
              let context,
              let tokenizeCode = context.objectForKeyedSubscript("tokenizeCode"),
              let result = tokenizeCode.call(withArguments: [code, language]),
              let array = result.toArray() as? [[String: String]] else {
            return [CodeSyntaxToken(content: code, type: "plain")]
        }

        let tokens = array.compactMap { token -> CodeSyntaxToken? in
            guard let content = token["content"], let type = token["type"] else {
                return nil
            }
            return CodeSyntaxToken(content: content, type: type)
        }
        return tokens.isEmpty ? [CodeSyntaxToken(content: code, type: "plain")] : tokens
    }

    private static func prismBundleURL() -> URL? {
        let bundleNames = [
            "textual_Textual.bundle",
            "Textual_Textual.bundle",
        ]

        for resourceURL in [Bundle.main.resourceURL, Bundle.main.bundleURL].compactMap(\.self) {
            for bundleName in bundleNames {
                let url = resourceURL
                    .appendingPathComponent(bundleName)
                    .appendingPathComponent("prism-bundle.js")
                if FileManager.default.fileExists(atPath: url.path) {
                    return url
                }
            }
        }

        for bundle in Bundle.allBundles {
            if let url = bundle.url(forResource: "prism-bundle", withExtension: "js") {
                return url
            }
        }

        return nil
    }
}
