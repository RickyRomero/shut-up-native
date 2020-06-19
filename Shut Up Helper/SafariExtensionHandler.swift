//
//  SafariExtensionHandler.swift
//  shutup Extension
//
//  Created by Ricky Romero on 9/2/19.
//  Copyright © 2019 Ricky Romero. All rights reserved.
//

import SafariServices

let basicBlocker = """
[
  {
    "action": {
      "selector": "p",
      "type": "css-display-none"
    },
    "trigger": {
      "url-filter": ".*"
    }
  }
]
"""

let complexBlocker = """
[
  {
    "action": {
      "selector": "p",
      "type": "css-display-none"
    },
    "trigger": {
      "unless-domain": [
        "*rickyromero.com"
      ],
      "url-filter": ".*"
    }
  }
]
"""

var clickCount = 0

class SafariExtensionHandler: SFSafariExtensionHandler {
    override init() {
        Setup.main.bootstrap {}

        print("Should be fetching now")
        Stylesheet.main.update(force: false) { error in
            print("done")
        }

        
//        print(Setup.main.counter)
        super.init()
    }

    override func beginRequest(with context: NSExtensionContext) {
        super.beginRequest(with: context)

        Setup.main.bootstrap {}

        print(#function)
        NSLog(Info.bundleId)
//        try? Setup.encryption()
    }

    override func toolbarItemClicked(in window: SFSafariWindow) {
        print("Whitelist load finished:", Whitelist.main.loadFinished)
        print(Whitelist.main.entries)
        window.getActiveTab { tab in
            tab?.getActivePage { page in
                page?.getPropertiesWithCompletionHandler { properties in
                    guard let domain = properties?.url?.host else { return }
                    print("Page properties", domain)
                    Whitelist.main.toggle(domain: domain)
                    print(Whitelist.main.entries)
                }
            }
        }

        print(#function)
        // This method will be called when your toolbar item is clicked.
        NSLog("com.rickyromero.shutup.blocker helper The extension's toolbar item was clicked")
        clickCount += 1
        print(clickCount % 2 == 1)

//        let blockerContents = (clickCount % 2 == 1) ? basicBlocker : complexBlocker
        let blockerContents = basicBlocker
        do {
            try blockerContents.write(to: Info.tempBlocklistUrl, atomically: true, encoding: .utf8)
        } catch {
            print(error.localizedDescription)
        }
        
        NSLog("com.rickyromero.shutup.blocker helper wrote, reloading content blocker!!!")
        SFContentBlockerManager.reloadContentBlocker(withIdentifier: Info.blockerBundleId) { error in
            if (error != nil)
            {
                NSLog("com.rickyromero.shutup.blocker helper error: \(error!.localizedDescription)")
            }
            else
            {
//                NSSound.beep()

                NSLog("com.rickyromero.shutup.blocker helper blocker updated!!!")
                window.getActiveTab { tab in
                    tab?.getActivePage { page in
                        page?.reload()
                        NSLog("ok i did it!!!")
                    }
                }
            }
        }
    }

    override func validateToolbarItem(in window: SFSafariWindow, validationHandler: @escaping ((Bool, String) -> Void)) {
        print(#function)

        window.getActiveTab { tab in
            tab?.getActivePage { page in
                page?.getPropertiesWithCompletionHandler { props in
                    print(props?.url?.host)
                    let enabled = ["http", "https"].contains(props?.url?.scheme ?? "")
                    validationHandler(enabled, "")
                }
            }
        }
//        window.getToolbarItem {(button: SFSafariToolbarItem?) in
//            let image = NSImage.init(contentsOf: Bundle.main.url(forResource: "turn-on", withExtension: "pdf")!)
//            //            button?.setImage(image)
//            //            button?.setEnabled(false)
//        }
    }

    override func validateContextMenuItem(withCommand command: String, in page: SFSafariPage, userInfo: [String : Any]? = nil, validationHandler: @escaping (Bool, String?) -> Void) {
        print(#function)
        validationHandler(false, nil)
    }

    func completeLoad(error: Error?) {
        print(#function)
        if (error != nil)
        {
            print(error!)
        }
        else
        {
            NSLog("completeLoad!!!")
        }
    }
}
