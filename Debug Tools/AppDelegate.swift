import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    @IBOutlet weak var window: NSWindow!
    @IBOutlet weak var keychainDataView: NSTableView!

    var keychainData: [[String: Any]]?
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        self.window.makeKeyAndOrderFront(self)
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

        var instances: [String: Int] = [:]

        for row in keychainData! {
            for col in row {
                print(col)
                if instances[col.key] == nil {
                    instances[col.key] = 1
                } else {
                    instances[col.key]! += 1
                }
            }
        }

        dump(instances)
    }

    private func dumpAction() -> [[String: Any]]? {
        print("will dump")
        var copyResult: CFTypeRef? = nil
        let err = SecItemCopyMatching([
            kSecClass: kSecClassKey,
            kSecMatchLimit: kSecMatchLimitAll,
//            kSecAttrSynchronizable: true,
            kSecReturnAttributes: true,
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

    private func resetAction() {
        print("will reset")
        let err = SecItemDelete([
            kSecClass: kSecClassKey,
            kSecMatchLimit: kSecMatchLimitAll,
            kSecAttrSynchronizable: true,
        ] as NSDictionary)
        switch err {
        case errSecSuccess, errSecItemNotFound:
            break
        default:
            print("did not dump, err: \(err)")
            return
        }
        print("did reset")
    }
}

extension AppDelegate: NSTableViewDelegate, NSTableViewDataSource {
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
