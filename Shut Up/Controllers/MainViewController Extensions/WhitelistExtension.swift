//
//  Whitelist.swift
//  Shut Up
//
//  Created by Ricky Romero on 6/14/20.
//  Copyright © 2020 Ricky Romero. All rights reserved.
//

import Cocoa

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
                change(from: whitelistTableEntries[row], to: domain)
            } else {
                sender.stringValue = whitelistTableEntries[row]
            }
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
                undoManager?.setActionName("Add \(undoString(from: domainsAdded))")
            }

            reloadTableData()
        }
    }

    func remove(domains: [String]) {
        let domainsRemoved = Whitelist.main.remove(domains: domains)
        if domainsRemoved.count > 0 {
            undoManager?.registerUndo(withTarget: self, handler: { targetType in
                targetType.add(domains: domainsRemoved)
            })

            if let actionName = undoManager?.undoActionName, actionName == "" {
                undoManager?.setActionName("Delete \(undoString(from: domainsRemoved))")
            }

            reloadTableData()
        }
    }

    func change(from: String, to: String) {
        _ = Whitelist.main.remove(domains: [from])
        _ = Whitelist.main.add(domains: [to])

        undoManager?.registerUndo(withTarget: self, handler: { targetType in
            targetType.change(from: to, to: from)
        })
        undoManager?.setActionName("Edit Domain")

        reloadTableData()
    }

    func undoString(from domains: [String]) -> String {
        if domains.count == 1 { return domains[0] }
        return "\(domains.count) Domains"
    }

    @IBAction func delete(_ sender: AnyObject) {
        let domainsToRemove = whitelistView.selectedRowIndexes.map { row in
            Whitelist.main.entries[row]
        }
        remove(domains: domainsToRemove)
    }

    func reloadTableData() {
        if #available(macOS 10.15, *) {
            whitelistView.beginUpdates()
            let diff = Whitelist.main.entries.difference(from: whitelistTableEntries)

            diff.forEach { change in
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
        } else {
            whitelistTableEntries = Whitelist.main.entries
            whitelistView.reloadData()
        }
    }
}

// MARK: NSTableViewDataSource

extension MainViewController: NSTableViewDataSource {
    // Return cell views
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let cellId = NSUserInterfaceItemIdentifier("WhitelistCell")
        let cell = whitelistView.makeView(withIdentifier: cellId, owner: nil) as? NSTableCellView
        if let cell = cell {
            let domain = whitelistTableEntries[row]
            cell.textField?.stringValue = domain
        }
        return cell
    }

    // Return number of available rows
    func numberOfRows(in tableView: NSTableView) -> Int {
        return whitelistTableEntries.count
    }
}

// MARK: NSTableViewDelegate

extension MainViewController: NSTableViewDelegate {
    // Swipe actions for the table view
    func tableView(_ tableView: NSTableView, rowActionsForRow row: Int, edge: NSTableView.RowActionEdge) -> [NSTableViewRowAction] {
        if (edge == .trailing) {
            let deleteAction = NSTableViewRowAction(style: .destructive, title: "Delete", handler: { rowAction, row in
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
        if menuItem.title == "Delete" {
            return whitelistView.selectedRowIndexes.count > 0
        }
        return true
    }
}
