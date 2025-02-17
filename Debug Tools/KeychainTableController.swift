//
//  KeychainTableController.swift
//  Debug Tools
//
//  Created by Ricky Romero on 6/6/20.
//  See LICENSE.md for license information.
//

import Cocoa

class KeychainTableController: NSViewController {
    @IBOutlet var keychainDataView: NSTableView!
    @IBOutlet var deleteMenuItem: NSMenuItem!
    var keychainData: [[CFString: Any]]?

    override func viewDidLoad() {
        keychainDataView.delegate = self
        keychainDataView.dataSource = self

        NotificationCenter.default.addObserver(
            forName: NSApplication.willBecomeActiveNotification,
            object: nil,
            queue: .main,
            using: enterForeground(_:)
        )
    }

    func enterForeground(_: Notification) {
        keychainData = dumpAction()
        keychainDataView.reloadData()
    }

    private func dumpAction() -> [[CFString: Any]]? {
        print("will dump")
        var copyResult: CFTypeRef? = nil
        let err = SecItemCopyMatching([
            kSecClass: kSecClassKey,
            kSecMatchLimit: kSecMatchLimitAll,
            kSecAttrSynchronizable: kSecAttrSynchronizableAny,
            kSecReturnAttributes: true
        ] as NSDictionary, &copyResult)
        let keysInfos: [[CFString: Any]]?
        switch err {
        case errSecSuccess:
            keysInfos = copyResult as? [[CFString: Any]]
        case errSecItemNotFound:
            keysInfos = []
        default:
            print("did not dump, err: \(err)")
            return nil
        }
        print("did dump")
        return keysInfos
    }

    private func deleteItem(at index: Int) {
        guard let target = keychainData?[index] else { return }
        guard let deletionQuery = constructDeletionQuery(using: target) else { return }

        print("will delete")
        let err = SecItemDelete(deletionQuery as NSDictionary)
        switch err {
        case errSecSuccess:
            break
        default:
            print("did not delete, err: \(err)")
            print((SecCopyErrorMessageString(err, nil) as String?) ?? "No error string available")
            return
        }

        keychainDataView.deselectRow(index)
        print("did delete")
    }

    private func constructDeletionQuery(using data: [CFString: Any]) -> [CFString: Any]? {
//        if let targetRef = data[String(kSecValueRef)] {
//            return [
//                kSecClass: kSecClassKey,
//                kSecMatchItemList: [targetRef] as CFArray
//            ]
//        }

        if let cdat = data[kSecAttrCreationDate], let mdat = data[kSecAttrModificationDate] {
            return [
                kSecClass: kSecClassKey,
                kSecAttrSynchronizable: kSecAttrSynchronizableAny,
                kSecAttrCreationDate: cdat,
                kSecAttrModificationDate: mdat
            ]
        }

        return nil
    }
}

// MARK: NSTableViewDelegate

extension KeychainTableController: NSTableViewDelegate {}

// MARK: NSTableViewDataSource

extension KeychainTableController: NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        return keychainData?.count ?? 0
    }

    func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
        let rowData = keychainData?[row]

        guard let columnId = tableColumn?.identifier.rawValue else { return "--" }
        guard let cellData = rowData?[columnId as CFString] else { return "--" }

        return String(describing: cellData)
    }
}

// MARK: Edit menu responders

extension KeychainTableController {
    @IBAction func delete(_ sender: AnyObject) {
        print("Baleeted")
        dump(keychainDataView.selectedRowIndexes)

        keychainDataView.selectedRowIndexes.forEach(deleteItem(at:))

        keychainData = dumpAction()
        keychainDataView.reloadData()
    }
}

extension KeychainTableController: NSMenuItemValidation {
    func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
        if menuItem == deleteMenuItem {
            return keychainDataView.selectedRowIndexes.count > 0
        }
        return true
    }
}
