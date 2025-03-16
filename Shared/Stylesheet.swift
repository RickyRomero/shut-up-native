//
//  Stylesheet.swift
//  shutup
//
//  Created by Ricky Romero on 5/22/20.
//  See LICENSE.md for license information.
//

import Foundation
import SafariServices

struct Rule {
    let source: String

    var selectors: [String] {
        let selectorList = source
            .split(separator: "{")[0]
            .components(separatedBy: ", ")

        return selectorList.map { $0.trim() }
    }

    var type: RuleType {
        let declarationString = source.split(separator: "{")[1]

        if declarationString.lowercased().contains("none") {
            return .blocking
        } else {
            return .undoing
        }
    }
}

enum RuleType {
    case blocking
    case undoing
}

class Stylesheet {
    static var main = Stylesheet()
    private init() {}

    private var waitingForResponse = false
    private var currentRefreshMethod: String?
    private var completionHandler: ((Error?) -> Void)?

    private let file = EncryptedFile(
        fsLocation: Info.localCssUrl,
        bundleOrigin: Bundle.main.url(forResource: "shutup", withExtension: "css")!
    )

    var updateIsDue: Bool {
        let twoDays: Double = 60 * 60 * 24 * 2
        let deadline = Preferences.main.lastStylesheetUpdate.addingTimeInterval(twoDays)

        return deadline.timeIntervalSinceNow < 0.0
    }

    var rules: [Rule] {
        guard let data = file.read() else { return [] }
        guard let cssString = String(data: data, encoding: .utf8) else { return [] }

        var ruleStrings = minify(css: cssString).split(separator: "}")
        ruleStrings = ruleStrings.filter { $0.trim().count > 0 }

        return ruleStrings.map { Rule(source: String($0)) }
    }

    func update(force: Bool = false, completionHandler: ((Error?) -> Void)?) {
        guard waitingForResponse == false else { return }
        guard updateIsDue || force else { return }

        waitingForResponse = true
        currentRefreshMethod = force ? "manual" : "automatic"

        self.completionHandler = completionHandler
        let stylesheetUrl = URL(string: "https://rickyromero.com/shutup/updates/shutup.css")!

        let sessionConfig = URLSessionConfiguration.ephemeral
        sessionConfig.httpAdditionalHeaders = [
            "User-Agent": "\(Info.productName)/\(Info.version) (\(Info.buildNum))",
        ]
        if !force, Preferences.main.etag != "" {
            sessionConfig.httpAdditionalHeaders?["If-None-Match"] = Preferences.main.etag
        }
        sessionConfig.timeoutIntervalForRequest = 10 // seconds

        let session = URLSession(configuration: sessionConfig)
        let sessionTask = session.dataTask(with: stylesheetUrl, completionHandler: handleServerResponse(data:response:error:))

        sessionTask.resume()
    }

    func handleServerResponse(data: Data?, response: URLResponse?, error: Error?) {
        var outputError: Error?
        defer {
            waitingForResponse = false
            currentRefreshMethod = nil
            DispatchQueue.main.async {
                self.completionHandler?(outputError)
                self.completionHandler = nil
            }
        }

        guard error == nil else {
            print("Encountered an error when updating the stylesheet:")
            print(error!.localizedDescription)
            outputError = error
            return
        }

        guard let data else {
            print("No data received from request.")
            return
        }

        guard let response = response as? HTTPURLResponse else {
            print("No response received from request.")
            return
        }

        let contentBlockerGroup = DispatchGroup()
        if data.count > 0, response.statusCode == 200 {
            guard validateCss(css: data) else {
                outputError = MiscError.unexpectedNetworkResponse
                return
            }

            do {
                try file.write(data: data)

                contentBlockerGroup.enter()
                SFContentBlockerManager.reloadContentBlocker(withIdentifier: Info.blockerBundleId) { error in
                    if error != nil {
                        outputError = BrowserError.providingBlockRules
                    }
                    contentBlockerGroup.leave()
                }
            } catch {
                if error is CryptoError {
                    outputError = error
                } else {
                    outputError = FileError.writingFile
                }
                return
            }
        } else if data.count == 0, response.statusCode == 304 {
            // Stylesheet is unmodified; continue
        } else {
            outputError = MiscError.unexpectedNetworkResponse
            return
        }

        Preferences.main.lastStylesheetUpdate = Date()
        Preferences.main.lastUpdateMethod = currentRefreshMethod ?? "automatic"
        let headers = response.allHeaderFields
        if let etag = headers["Etag"] as? String {
            Preferences.main.etag = etag
        }

        contentBlockerGroup.wait()
    }

    private func validateCss(css: Data) -> Bool {
        guard css.count < 2 * 1024 * 1024 else { return false }
        guard var cssString = String(data: css, encoding: .utf8) else { return false }

        cssString = minify(css: cssString)

        // Verify a matching number of opening and closing braces
        let openBraceCount = cssString.split(separator: "{").count - 1
        let closeBraceCount = cssString.split(separator: "}").count - 1
        guard openBraceCount == closeBraceCount else { return false }

        var allPairsValid = true
        var displayNoneFound = false
        for selectorRulePair in cssString.split(separator: "}") {
            // Special case for ending bracket
            guard selectorRulePair.trim().count > 0 else { continue }

            let selectorRulePair = selectorRulePair.split(separator: "{")
            let selectorSet = selectorRulePair[0].trim()
            let ruleSet = selectorRulePair[1].trim()

            // Check for a list of (fairly short) selectors
            for selector in selectorSet.components(separatedBy: ", ") {
                allPairsValid = allPairsValid && selector.trim().count < 150
            }

            guard let displayPropRegex = try? NSRegularExpression(
                pattern: "display:\\s*[a-z\\- ]+\\s+!important;?",
                options: .caseInsensitive
            ) else {
                return false
            }
            allPairsValid = allPairsValid && displayPropRegex.test(ruleSet)

            guard let displayNoneRegex = try? NSRegularExpression(
                pattern: "display:\\s*none\\s+!important;?",
                options: .caseInsensitive
            ) else {
                return false
            }
            displayNoneFound = displayNoneFound || displayNoneRegex.test(ruleSet)
        }

        return allPairsValid && displayNoneFound
    }

    private func minify(css: String) -> String {
        let cleanupPatterns = [
            // swiftformat:disable consecutiveSpaces
            ["\\s*/\\*.+?\\*/\\s*", " "],   // Comments
            ["^\\s+",               ""],    // Leading whitespace
            [",\\s+",               ", "],  // Selector whitespace
            // swiftformat:enable consecutiveSpaces
        ]

        var strippedCSS = css
        for replacementPair in cleanupPatterns {
            let cleanupPattern = replacementPair[0]
            let replacementTemplate = replacementPair[1]
            guard let cleanupRegex = try? NSRegularExpression(pattern: cleanupPattern, options: .dotMatchesLineSeparators) else {
                continue
            }
            strippedCSS = cleanupRegex.stringByReplacingMatches(
                in: strippedCSS,
                options: [],
                range: NSMakeRange(0, strippedCSS.count),
                withTemplate: replacementTemplate
            )
        }

        return strippedCSS
    }

    func reset() { file.reset() }
}

// MARK: String/regex convenience extensions

private extension String {
    func trim() -> String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

private extension Substring {
    func trim() -> String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

private extension NSRegularExpression {
    func test(_ string: String) -> Bool {
        firstMatch(in: string, options: [], range: NSMakeRange(0, string.count)) != nil
    }
}
