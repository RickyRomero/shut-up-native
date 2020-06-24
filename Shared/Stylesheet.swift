//
//  Stylesheet.swift
//  shutup
//
//  Created by Ricky Romero on 5/22/20.
//  Copyright © 2020 Ricky Romero. All rights reserved.
//

import Foundation

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

    func update(force: Bool, completionHandler: ((Error?) -> Void)?) {
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
        defer {
            Preferences.main.lastStylesheetUpdate = Date()
            waitingForResponse = false
            DispatchQueue.main.async {
                self.completionHandler?(error)
                self.completionHandler = nil
            }
        }

        guard error == nil else {
            print("Encountered an error when updating the stylesheet:")
            print(error!.localizedDescription)
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

        let headers = response.allHeaderFields
        if let etag = headers["Etag"] as? String {
            Preferences.main.etag = etag
        }

        if data.count > 0 { // TODO: Validate!
            do {
                try file.write(data: data)
            } catch {
                if error is CryptoError {
                    showError(error)
                } else {
                    showError(FileError.writingFile)
                }
                return
            }
        }
//        print(String(data: data, encoding: .utf8)!)
    }

    func parseCss(css: Data) {
        
    }

    func reset() { file.reset() }
}


func selector(from css: String) -> String {
    let strippedCSS = minify(css: css)

    let displayNoneRegex = try! NSRegularExpression(pattern: "display:\\s*none", options: .caseInsensitive)
    let declarationBlocks = strippedCSS.components(separatedBy: "}")
    let selectorWhitespaceRegex = try! NSRegularExpression(pattern: "^\\s+|\\s+$", options: .dotMatchesLineSeparators)
    let concatString = ", "

    var displayNoneCount = 0
    var selector = ""
    var fullSelector: [String] = []

    for block in declarationBlocks {
        displayNoneCount = displayNoneRegex.numberOfMatches(
            in: block,
            options: NSRegularExpression.MatchingOptions(),
            range: NSMakeRange(0, block.count)
        )
        
        if displayNoneCount > 0 {
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

func minify(css: String) -> String {
    let cleanupPatterns = [
        ["/\\*.+?\\*/", ""],    // Comments
        ["^\\s+",       ""],    // Leading whitespace
        [",\\s+",       ", "],  // Selector whitespace
    ]

    var strippedCSS = css
    var cleanupPattern: String!
    var replacementTemplate: String!
    var cleanupRegex: NSRegularExpression!
    for replacementPair in cleanupPatterns {
        cleanupPattern = replacementPair[0]
        replacementTemplate = replacementPair[1]
        cleanupRegex = try! NSRegularExpression(pattern: cleanupPattern, options: NSRegularExpression.Options.dotMatchesLineSeparators)
        strippedCSS = cleanupRegex.stringByReplacingMatches(in: strippedCSS,
            options: NSRegularExpression.MatchingOptions(),
            range: NSMakeRange(0, strippedCSS.count),
            withTemplate: replacementTemplate)
    }

    print(strippedCSS)

    return strippedCSS
}
