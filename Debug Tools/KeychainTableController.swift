//
//  KeychainTableController.swift
//  Debug Tools
//
//  Created by Ricky Romero on 6/6/20.
//  Copyright © 2020 Ricky Romero. All rights reserved.
//

import Cocoa

class KeychainTableController: NSViewController {
    @IBOutlet weak var keychainDataView: NSTableView!
    @IBOutlet weak var deleteMenuItem: NSMenuItem!
    var keychainData: [[String: Any]]?

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

    private func dumpAction() -> [[String: Any]]? {
        print("will dump")
        var copyResult: CFTypeRef? = nil
        let err = SecItemCopyMatching([
            kSecClass: kSecClassKey,
            kSecMatchLimit: kSecMatchLimitAll,
            kSecReturnAttributes: true
        ] as NSDictionary, &copyResult)
        let keysInfos: [[String:Any]]
        switch err {
        case errSecSuccess:
            keysInfos = copyResult! as! NSArray as! [[String:Any]]
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
            print(SecCopyErrorMessageString(err, nil))
            return
        }

        keychainDataView.deselectRow(index)
        print("did delete")
    }

    private func constructDeletionQuery(using data: [String: Any]) -> [CFString: Any]? {
//        if let targetRef = data[String(kSecValueRef)] {
//            return [
//                kSecClass: kSecClassKey,
//                kSecMatchItemList: [targetRef] as CFArray
//            ]
//        }

        if let cdat = data[String(kSecAttrCreationDate)], let mdat = data[String(kSecAttrModificationDate)] {
            return [
                kSecClass: kSecClassKey,
                kSecAttrCreationDate: cdat,
                kSecAttrModificationDate: mdat
            ]
        }

        return nil
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

extension KeychainTableController: NSTableViewDelegate {
}

extension KeychainTableController: NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        return keychainData?.count ?? 0
    }

    func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
        let rowData = keychainData?[row]

        let columnId = tableColumn?.identifier.rawValue
        guard columnId != nil else { return "--" }

        let cellData = rowData?[String(columnId!)]
        guard cellData != nil else { return "--" }

        return String(describing: cellData!)
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
