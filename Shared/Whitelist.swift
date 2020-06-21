//
//  Whitelist.swift
//  Shut Up
//
//  Created by Ricky Romero on 6/16/20.
//  Copyright © 2020 Ricky Romero. All rights reserved.
//

import Cocoa

class Whitelist {
    static var main = Whitelist()
    private init() {
        file = EncryptedFile(
            fsLocation: Info.whitelistUrl,
            bundleOrigin: Bundle.main.url(forResource: "domain-whitelist", withExtension: "json")!
        )

        self.load()
        DispatchQueue.main.async {
            self.delegate?.newWhitelistDataAvailable()
        }

        self.file.externalUpdateOccurred = { data in
            self.load()

            DispatchQueue.main.async {
                self.delegate?.newWhitelistDataAvailable()
            }
        }
    }

    private var _delegate: WhitelistDataDelegate?
    var delegate: WhitelistDataDelegate? {
        get { _delegate }
        set {
            _delegate = newValue
            _delegate?.newWhitelistDataAvailable()
        }
    }
    private var _entries: [String] = []
    var entries: [String] {
        get { _entries }
        set { _entries = newValue.sorted() }
    }

    private var file: EncryptedFile!
    var loadFinished = false

    static func parseDomain(from item: String) -> String? {
        guard item.count > 0 else { return nil }

        let item = item.lowercased()
        let detector = try! NSDataDetector(
            types: NSTextCheckingResult.CheckingType.link.rawValue
        )
        let match = detector.firstMatch(
            in: item,
            options: [],
            range: NSRange(location: 0, length: item.utf16.count)
        )

        // Try using NSDataDetector to see if we're dealing with something that looks
        // to the operating system like a link
        if let match = match {
            // It's a link if the match covers the whole string
            guard match.range.length == item.utf16.count else { return nil }

            // Attempt to parse the hostname out if the NSDataDetector found something
            if let parsedDomain = URL(string: item)?.host { return parsedDomain }
        }

        // Fallback tests, for weird TLDs
        // First check: Is it the correct length?
        guard item.count <= 253 else { return nil }
        
        // Second check: Does it have the correct number of dots?
        let subdivisions = item.components(separatedBy: ".").count - 1
        guard (1..<127).contains(subdivisions) else { return nil }
        
        // Final check: Does it pass a regex test?
        let domainNameRegex = try! NSRegularExpression(
            pattern: "^(?:[a-z0-9\\-]{1,63}\\.){1,126}[a-z0-9\\-]{1,63}$",
            options: NSRegularExpression.Options()
        )
        let domainNameCount = domainNameRegex.numberOfMatches(
            in: item,
            options: [],
            range: NSMakeRange(0, item.count)
        )
        guard domainNameCount > 0 else { return nil }
        
        return item
    }

    func load() {
        guard let data = file.read() else { return }

        do {
            let decoder = JSONDecoder()
            let whitelistData = try decoder.decode([String].self, from: data)

            entries = whitelistData
            loadFinished = true
        } catch {
            if error is CryptoError {
                NSApp.presentError(MessagingError(error))
            } else {
                NSApp.presentError(MessagingError(FileError.readingFile))
            }
            return
        }
    }

    func save() {
        do {
            let encoder = JSONEncoder()
            let whitelistData = try encoder.encode(entries)

            try file.write(data: whitelistData)
        } catch {
            if error is CryptoError {
                NSApp.presentError(MessagingError(error))
            } else {
                NSApp.presentError(MessagingError(FileError.writingFile))
            }
            return
        }
    }

    func add(domain: String) -> Bool {
        guard loadFinished else { return false }
        guard !entries.contains(domain) else { return false }

        entries.append(domain)
        save()

        return true
    }

    func remove(domain: String) -> Bool {
        guard loadFinished else { return false }
        guard entries.contains(domain) else { return false }

        entries.remove(at: entries.firstIndex(of: domain)!)
        save()

        return true
    }

    func toggle(domain: String) -> Bool {
        if entries.contains(domain) {
            return remove(domain: domain)
        } else {
            return add(domain: domain)
        }
    }

    func reset() { file.reset() }
}

protocol WhitelistDataDelegate {
    func newWhitelistDataAvailable()
}
