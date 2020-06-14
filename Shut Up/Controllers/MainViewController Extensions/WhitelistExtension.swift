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
    }
}

// MARK: NSTableViewDataSource

extension MainViewController: NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        return 40
    }
}

// MARK: NSTableViewDelegate

extension MainViewController: NSTableViewDelegate {
    func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
        return "Hello table!"
    }

    // Swipe actions for the table view
    func tableView(_ tableView: NSTableView, rowActionsForRow row: Int, edge: NSTableView.RowActionEdge) -> [NSTableViewRowAction] {
        if (edge == .leading) {
            let saveAction = NSTableViewRowAction(style: .regular, title: "Permanent", handler: { rowAction, row in
                print("Saving...")
            })
            saveAction.backgroundColor = .cyan
            return [saveAction]
        } else if (edge == .trailing) {
            let deleteAction = NSTableViewRowAction(style: .destructive, title: "Delete", handler: { rowAction, row in
                print("Deleting...")
                self.whitelistView.removeRows(at: IndexSet(integer: row), withAnimation: .effectFade)
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

// MARK: NSTextFieldDelegate

extension MainViewController: NSTextFieldDelegate {
    func controlTextDidBeginEditing(_ obj: Notification) {
        print(#function)
    }
    func controlTextDidEndEditing(_ obj: Notification) {
        print(#function)
    }
}
