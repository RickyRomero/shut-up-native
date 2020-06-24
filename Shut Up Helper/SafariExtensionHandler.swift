//
//  SafariExtensionHandler.swift
//  shutup Extension
//
//  Created by Ricky Romero on 9/2/19.
//  Copyright © 2019 Ricky Romero. All rights reserved.
//

import SafariServices

class SafariExtensionHandler: SFSafariExtensionHandler {
    struct toolbarImages {
        private static let enabledUrl = Bundle.main.urlForImageResource("turn-off")!
        private static let disabledUrl = Bundle.main.urlForImageResource("turn-on")!

        static let enabled = NSImage(contentsOfFile: enabledUrl.path)
        static let disabled = NSImage(contentsOfFile: disabledUrl.path)
    }

    override func beginRequest(with context: NSExtensionContext) {
        Setup.main.bootstrap {}
    }

    override func toolbarItemClicked(in window: SFSafariWindow) {
        window.getActiveTab { tab in
            tab?.getActivePage { page in
                page?.getPropertiesWithCompletionHandler { properties in
                    guard let fullHost = properties?.url?.host else { return }
                    let domain = Whitelist.stripWww(from: fullHost)
                    _ = Whitelist.main.toggle(domain: domain)

                    window.getToolbarItem { button in
                        let matched = Whitelist.main.matches(domain: domain)
                        let icon = matched ? toolbarImages.enabled : toolbarImages.disabled
                        button?.setImage(icon)
                    }

                    SFContentBlockerManager.reloadContentBlocker(withIdentifier: Info.blockerBundleId) { error in
                        guard error == nil else {
                            NSLog("com.rickyromero.shutup.blocker helper error: \(error!.localizedDescription)")
                            return
                        }

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
}

func showError(_: Error) {}
