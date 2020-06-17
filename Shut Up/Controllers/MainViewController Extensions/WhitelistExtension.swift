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
        print(#function)
        print("action")

        guard let domain = Whitelist.parseDomain(from: sender.stringValue) else {
            NSSound.beep()
            return
        }

        print(domain)
        sender.stringValue = ""
    }
}

// MARK: NSTableViewDataSource

extension MainViewController: NSTableViewDataSource {
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let cellId = NSUserInterfaceItemIdentifier("WhitelistCell")
        let cell = whitelistView.makeView(withIdentifier: cellId, owner: nil) as? NSTableCellView
        if let cell = cell {
            cell.textField?.stringValue = "\(row)"
        }
        return cell
    }

    func numberOfRows(in tableView: NSTableView) -> Int {
        return 400
    }
}

// MARK: NSTableViewDelegate

extension MainViewController: NSTableViewDelegate {
    // Swipe actions for the table view
    func tableView(_ tableView: NSTableView, rowActionsForRow row: Int, edge: NSTableView.RowActionEdge) -> [NSTableViewRowAction] {
        if (edge == .trailing) {
            let deleteAction = NSTableViewRowAction(style: .destructive, title: "Delete", handler: { rowAction, row in
                print("Deleting...")
                self.whitelistView.removeRows(
                    at: IndexSet(integer: row),
                    withAnimation: .effectFade
                )
            })
            deleteAction.backgroundColor = .red
            return [deleteAction]
        }
        return []
    }

    func tableView(_ tableView: NSTableView, didRemove rowView: NSTableRowView, forRow row: Int) {
        print("Hey. We're removing a row. It's row \(row).")
    }
}
