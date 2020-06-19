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

        Stylesheet.main.update(force: false) { error in
        }

        
//        print(Setup.main.counter)
        super.init()
    }

    override func beginRequest(with context: NSExtensionContext) {
        super.beginRequest(with: context)

        Setup.main.bootstrap {}

//        try? Setup.encryption()
    }

    override func toolbarItemClicked(in window: SFSafariWindow) {
        window.getActiveTab { tab in
            tab?.getActivePage { page in
                page?.getPropertiesWithCompletionHandler { properties in
                    guard let domain = properties?.url?.host else { return }
                    Whitelist.main.toggle(domain: domain)
                }
            }
        }

        // This method will be called when your toolbar item is clicked.
        clickCount += 1

//        let blockerContents = (clickCount % 2 == 1) ? basicBlocker : complexBlocker
        let blockerContents = basicBlocker
        do {
            try blockerContents.write(to: Info.tempBlocklistUrl, atomically: true, encoding: .utf8)
        } catch {
            print(error.localizedDescription)
        }
        
        SFContentBlockerManager.reloadContentBlocker(withIdentifier: Info.blockerBundleId) { error in
            if (error != nil)
            {
                NSLog("com.rickyromero.shutup.blocker helper error: \(error!.localizedDescription)")
            }
            else
            {
//                NSSound.beep()

                window.getActiveTab { tab in
                    tab?.getActivePage { page in
                        page?.reload()
                    }
                }
            }
        }
    }

    override func validateToolbarItem(in window: SFSafariWindow, validationHandler: @escaping ((Bool, String) -> Void)) {
        window.getActiveTab { tab in
            tab?.getActivePage { page in
                page?.getPropertiesWithCompletionHandler { props in
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
        validationHandler(false, nil)
    }

    func completeLoad(error: Error?) {
        if error != nil {
            print(error!)
        } else {
            NSLog("completeLoad!!!")
        }
    }
}
