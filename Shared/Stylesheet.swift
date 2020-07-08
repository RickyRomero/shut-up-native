//
//  Stylesheet.swift
//  shutup
//
//  Created by Ricky Romero on 5/22/20.
//  Copyright © 2020 Ricky Romero. All rights reserved.
//

import Foundation
import SafariServices

class Stylesheet {
    static var main = Stylesheet()
    private init() {}

    private var waitingForResponse = false
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

    func update(force: Bool = false, completionHandler: ((Error?) -> Void)?) {
        guard waitingForResponse == false else { return }
        guard updateIsDue || force else { return }

        waitingForResponse = true
        self.completionHandler = completionHandler
        let stylesheetUrl = URL(string: "https://rickyromero.com/shutup/updates/shutup.css")!

        let sessionConfig = URLSessionConfiguration.ephemeral
        sessionConfig.httpAdditionalHeaders = [
            "User-Agent": "\(Info.productName)/\(Info.version) (\(Info.buildNum))"
        ]
        if !force && Preferences.main.etag != "" {
            sessionConfig.httpAdditionalHeaders?["If-None-Match"] = Preferences.main.etag
        }
        sessionConfig.timeoutIntervalForRequest = 5 // seconds
        sessionConfig.timeoutIntervalForRequest = 10 // seconds

        let session = URLSession(configuration: sessionConfig)
        let sessionTask = session.dataTask(with: stylesheetUrl, completionHandler: handleServerResponse(data:response:error:))

        sessionTask.resume()
    }

    func handleServerResponse(data: Data?, response: URLResponse?, error: Error?) {
        var outputError: Error?
        defer {
            waitingForResponse = false
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

        guard let data = data else {
            print("No data received from request.")
            return
        }

        guard let response = response as? HTTPURLResponse else {
            print("No response received from request.")
            return
        }

        let contentBlockerGroup = DispatchGroup()
        if data.count > 0 && response.statusCode == 200 {
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
        } else if data.count == 0 && response.statusCode == 304 {
            // Stylesheet is unmodified; continue
        } else {
            outputError = MiscError.unexpectedNetworkResponse
            return
        }

        Preferences.main.lastStylesheetUpdate = Date()
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
        cssString.split(separator: "}").forEach { selectorRulePair in
            // Special case for ending bracket
            guard selectorRulePair.trim().count > 0 else { return }

            let selectorRulePair = selectorRulePair.split(separator: "{")
            let selectorSet = selectorRulePair[0].trim()
            let ruleSet = selectorRulePair[1].trim()

            // Check for a list of (fairly short) selectors
            selectorSet.components(separatedBy: ", ").forEach { selector in
                allPairsValid = allPairsValid && selector.trim().count < 150
            }

            // Check for a rule containing CSS display properties
            let displayPropRegex = try! NSRegularExpression(
                pattern: "display:\\s*[a-z\\- ]+\\s+!important;?",
                options: .caseInsensitive
            )
            allPairsValid = allPairsValid && displayPropRegex.test(ruleSet)

            // At least one "display: none !important" must be present
            let displayNoneRegex = try! NSRegularExpression(
                pattern: "display:\\s*none\\s+!important;?",
                options: .caseInsensitive
            )
            displayNoneFound = displayNoneFound || displayNoneRegex.test(ruleSet)
        }

        return allPairsValid && displayNoneFound
    }

    private func parseCss(css: Data) {
        
    }

    private func minify(css: String) -> String {
        let cleanupPatterns = [
            ["\\s*/\\*.+?\\*/\\s*", " "],    // Comments
            ["^\\s+",               ""],    // Leading whitespace
            [",\\s+",               ", "],  // Selector whitespace
        ]

        var strippedCSS = css
        for replacementPair in cleanupPatterns {
            let cleanupPattern = replacementPair[0]
            let replacementTemplate = replacementPair[1]
            let cleanupRegex = try! NSRegularExpression(pattern: cleanupPattern, options: .dotMatchesLineSeparators)
            strippedCSS = cleanupRegex.stringByReplacingMatches(
                in: strippedCSS,
                options: [],
                range: NSMakeRange(0, strippedCSS.count),
                withTemplate: replacementTemplate
            )
        }

        return strippedCSS
    }

    private func selector(from css: String) -> String {
        let strippedCSS = minify(css: css)

        let displayNoneRegex = try! NSRegularExpression(pattern: "display:\\s*none", options: .caseInsensitive)
        let declarationBlocks = strippedCSS.components(separatedBy: "}")
        let selectorWhitespaceRegex = try! NSRegularExpression(pattern: "^\\s+|\\s+$", options: .dotMatchesLineSeparators)
        let concatString = ", "

        var selector = ""
        var fullSelector: [String] = []

        for block in declarationBlocks {
            if displayNoneRegex.test(block) {
                selector = block.components(separatedBy: "{")[0]
                selector = selectorWhitespaceRegex.stringByReplacingMatches(
                    in: selector,
                    options: [],
                    range: NSMakeRange(0, selector.count),
                    withTemplate: ""
                )
                
                fullSelector.append(selector)
            }
        }

        return fullSelector.joined(separator: concatString)
    }

    func reset() { file.reset() }
}



// MARK: String/regex convenience extensions

fileprivate extension String {
    func trim() -> String {
        self.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

fileprivate extension Substring {
    func trim() -> String {
        self.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

fileprivate extension NSRegularExpression {
    func test(_ string: String) -> Bool {
        self.firstMatch(in: string, options: [], range: NSMakeRange(0, string.count)) != nil
    }
}
