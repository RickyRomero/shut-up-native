//
//  WhitelistExtension.swift
//  Shut Up
//
//  Created by Ricky Romero on 6/14/20.
//  See LICENSE.md for license information.
//

import Cocoa
import SafariServices

extension MainViewController {
    @IBAction func addAction(_ sender: NSTextField) {
        if let domain = verifyWhitelistEntry(for: sender.stringValue, on: nil) {
            sender.stringValue = ""
            add(domains: [domain])
        }
    }

    @IBAction func rowWasEdited(_ sender: NSTextField) {
        let row = whitelistView.row(for: sender)

        if row > -1 {
            if let domain = verifyWhitelistEntry(for: sender.stringValue, on: row) {
                sender.stringValue = domain
                change(from: whitelistTableEntries[row], into: domain)
            } else {
                sender.stringValue = whitelistTableEntries[row]
            }
        }
    }

    @IBAction func delete(_: AnyObject) {
        remove(domains: getSelectedDomains())
    }

    @IBAction func cut(_: AnyObject?) {
        // Capture the selected domains before deletion
        let selectedDomains = getSelectedDomains()

        // Perform the copy & delete action
        copy(nil)
        delete(self)

        // Override the undo action name to reflect a 'Cut' operation
        undoManager?.setActionName(String(localized: "Cut \(undoString(from: selectedDomains))"))
    }

    @IBAction func copy(_: AnyObject?) {
        let pasteboard = NSPasteboard.general
        pasteboard.declareTypes([.string], owner: nil)
        pasteboard.setString(
            getSelectedDomains().joined(separator: "\n").appending("\n"),
            forType: .string
        )
    }

    @IBAction func pasteAsPlainText(_: AnyObject?) {
        let pasteboard = NSPasteboard.general
        let startingCount = Whitelist.main.entries.count
        guard let clipboardContents = pasteboard.string(forType: .string) else {
            NSSound.beep()
            return
        }

        // Split the clipboard contents using comma, semicolon, space, newline, tab, and pipe as delimiters
        let delimiters = CharacterSet(charactersIn: ",; \n\t|")
        let tokens = clipboardContents.components(separatedBy: delimiters)
            .filter { !$0.isEmpty }

        let domains = tokens.compactMap { token -> String? in
            let cleanedToken = token.trimmingCharacters(in: .whitespacesAndNewlines)
                .trimmingCharacters(in: CharacterSet(charactersIn: "/"))
            guard let domain = Whitelist.parseDomain(from: cleanedToken) else { return nil }

            // Additional regex check to ensure the domain is valid
            guard let validDomainRegex = try? NSRegularExpression(
                pattern: "^(?:[a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?\\.)+(?:[a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?)$",
                options: []
            ) else {
                return nil
            }
            let range = NSRange(location: 0, length: domain.utf16.count)
            let matches = validDomainRegex.numberOfMatches(in: domain, options: [], range: range)
            guard matches > 0 else { return nil }

            return domain
        }

        let dedupedDomains = Array(Set(domains))
        add(domains: dedupedDomains)

        if startingCount == Whitelist.main.entries.count {
            NSSound.beep()
        }
    }

    func getSelectedDomains() -> [String] {
        whitelistView.selectedRowIndexes.map { row in
            Whitelist.main.entries[row]
        }
    }

    func verifyWhitelistEntry(for string: String, on row: Int?) -> String? {
        guard let domain = Whitelist.parseDomain(from: string) else {
            NSSound.beep()
            return nil
        }

        let index = Whitelist.firstIndex(of: domain, in: whitelistTableEntries)
        guard index == nil else {
            if index != row { NSSound.beep() }
            return nil
        }

        return domain
    }

    func add(domains: [String]) {
        let domainsAdded = Whitelist.main.add(domains: domains)
        if domainsAdded.count > 0 {
            undoManager?.registerUndo(withTarget: self, handler: { targetType in
                targetType.remove(domains: domainsAdded)
            })

            if let actionName = undoManager?.undoActionName, actionName == "" {
                undoManager?.setActionName(String(localized: "Add \(undoString(from: domainsAdded))"))
            }

            reloadTableData()
            updateContentBlocker()
        }
    }

    func remove(domains: [String]) {
        let domainsRemoved = Whitelist.main.remove(domains: domains)
        if domainsRemoved.count > 0 {
            undoManager?.registerUndo(withTarget: self, handler: { targetType in
                targetType.add(domains: domainsRemoved)
            })

            if let actionName = undoManager?.undoActionName, actionName == "" {
                undoManager?.setActionName(String(localized: "Delete \(undoString(from: domainsRemoved))"))
            }

            reloadTableData()
            updateContentBlocker()
        }
    }

    func change(from: String, into: String) {
        _ = Whitelist.main.remove(domains: [from])
        _ = Whitelist.main.add(domains: [into])

        undoManager?.registerUndo(withTarget: self, handler: { targetType in
            targetType.change(from: into, into: from)
        })
        undoManager?.setActionName("Edit Domain")

        reloadTableData()
        updateContentBlocker()
    }

    func undoString(from domains: [String]) -> String {
        if domains.count == 1 { return domains[0] }
        return String(localized: "\(domains.count) Domains")
    }

    func reloadTableData() {
        whitelistView.beginUpdates()
        let diff = Whitelist.main.entries.difference(from: whitelistTableEntries)

        for change in diff {
            switch change {
            case let .remove(offset, _, _):
                whitelistTableEntries.remove(at: offset)
                let indexSet = IndexSet([offset])
                whitelistView.removeRows(at: indexSet, withAnimation: .slideUp)
            case let .insert(offset, newElement, _):
                whitelistTableEntries.insert(newElement, at: offset)
                let indexSet = IndexSet([offset])
                whitelistView.insertRows(at: indexSet, withAnimation: .slideDown)
            }
        }
        whitelistView.endUpdates()
    }

    func updateContentBlocker() {
        SFContentBlockerManager.reloadContentBlocker(withIdentifier: Info.blockerBundleId) { error in
            guard error == nil else {
                showError(BrowserError.providingBlockRules)
                return
            }
        }
    }
}

// MARK: NSTableViewDataSource

extension MainViewController: NSTableViewDataSource {
    // Return cell views
    func tableView(_: NSTableView, viewFor _: NSTableColumn?, row: Int) -> NSView? {
        let cellId = NSUserInterfaceItemIdentifier("WhitelistCell")
        let cell = whitelistView.makeView(withIdentifier: cellId, owner: nil) as? NSTableCellView
        if let cell {
            let domain = whitelistTableEntries[row]
            cell.textField?.stringValue = domain
        }
        return cell
    }

    // Return number of available rows
    func numberOfRows(in _: NSTableView) -> Int {
        whitelistTableEntries.count
    }
}

// MARK: NSTableViewDelegate

extension MainViewController: NSTableViewDelegate {
    // Swipe actions for the table view
    func tableView(_: NSTableView, rowActionsForRow row: Int, edge: NSTableView.RowActionEdge) -> [NSTableViewRowAction] {
        if edge == .trailing {
            let deleteAction = NSTableViewRowAction(style: .destructive, title: String(localized: "Delete"), handler: { _, row in
                self.remove(domains: [Whitelist.main.entries[row]])
            })
            deleteAction.backgroundColor = .red
            return [deleteAction]
        }
        return []
    }
}

// MARK: WhitelistDataDelegate

extension MainViewController: WhitelistDataDelegate {
    func newWhitelistDataAvailable() {
        undoManager?.removeAllActions()
        reloadTableData()
    }
}

// MARK: WhitelistDataDelegate

extension MainViewController: NSMenuItemValidation {
    func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
        switch menuItem.identifier?.rawValue {
        case "menu_cut", "menu_copy", "menu_delete":
            whitelistView.selectedRowIndexes.count > 0
        default: true
        }
    }
}
