//
//  SafariExtensionHandler.swift
//  shutup Extension
//
//  Created by Ricky Romero on 9/2/19.
//  See LICENSE.md for license information.
//

import SafariServices

class SafariExtensionHandler: SFSafariExtensionHandler {
    enum toolbarImages {
        private static let enabledUrl = Bundle.main.urlForImageResource("turn-off")!
        private static let disabledUrl = Bundle.main.urlForImageResource("turn-on")!

        static let enabled = NSImage(contentsOfFile: enabledUrl.path)
        static let disabled = NSImage(contentsOfFile: disabledUrl.path)
    }

    override func beginRequest(with context: NSExtensionContext) {
        Setup.main.bootstrap {}
    }

    override func contextMenuItemSelected(withCommand command: String, in page: SFSafariPage, userInfo: [String: Any]? = nil) {
        page.getContainingTab { tab in
            tab.getContainingWindow { window in
                page.getPropertiesWithCompletionHandler { props in
                    self.toggleComments(for: window, with: page, having: props)
                }
            }
        }
    }

    override func toolbarItemClicked(in window: SFSafariWindow) {
        window.getActiveTab { tab in
            tab?.getActivePage { page in
                page?.getPropertiesWithCompletionHandler { props in
                    self.toggleComments(for: window, with: page, having: props)
                }
            }
        }
    }

    override func validateToolbarItem(in window: SFSafariWindow, validationHandler: @escaping ((Bool, String) -> Void)) {
        Whitelist.main.load()

        window.getActiveTab { tab in
            tab?.getActivePage { page in
                page?.getPropertiesWithCompletionHandler { props in
                    window.getToolbarItem { button in
                        self.updateIcon(in: button, for: props?.url)
                    }
                    let enabled = ["http", "https"].contains(props?.url?.scheme ?? "")
                    validationHandler(enabled, "")
                }
            }
        }
    }

    func toggleComments(for window: SFSafariWindow?, with page: SFSafariPage?, having props: SFSafariPageProperties?) {
        guard let domain = getDomain(from: props?.url) else { return }
        _ = Whitelist.main.toggle(domain: domain)

        window?.getToolbarItem { button in
            self.updateIcon(in: button, for: props?.url)
        }

        SFContentBlockerManager.reloadContentBlocker(withIdentifier: Info.blockerBundleId) { error in
            guard error == nil else {
                NSLog("com.rickyromero.shutup.blocker helper error: \(error!.localizedDescription)")
                return
            }

            // This event lies, dispatching the completion handler sometimes
            // long before it's ready.
            // The discrepancy may be dependent upon how many rules from all
            // content blockers are being recompiled during this step.
            // I have quite a few blockers installed now, and I had to increase
            // this artificial delay from 50ms all the way to 550ms.
            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(550)) {
                page?.reload()
            }

            let shouldRemove = (
                !Preferences.main.automaticWhitelisting ||
                    (props?.usesPrivateBrowsing ?? false)
            )
            if shouldRemove {
                // Unfortunately this also requires an ugly delay...
                DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1)) {
                    _ = Whitelist.main.remove(domains: [domain])
                    SFContentBlockerManager.reloadContentBlocker(
                        withIdentifier: Info.blockerBundleId,
                        completionHandler: nil
                    )
                }
            }
        }
    }

    func getDomain(from url: URL?) -> String? {
        guard let fullHost = url?.host else { return nil }
        return Whitelist.stripWww(from: fullHost)
    }

    func updateIcon(in button: SFSafariToolbarItem?, for url: URL?) {
        guard let domain = getDomain(from: url) else { return }

        let matched = Whitelist.main.matches(domain: domain)
        let icon = matched ? toolbarImages.disabled : toolbarImages.enabled
        button?.setImage(icon)
        button?.setLabel(matched
            ? String(localized: "Hide Comments", comment: "Toolbar button label")
            : String(localized: "Show Comments", comment: "Toolbar button label"))
    }

    override func validateContextMenuItem(withCommand command: String,
                                          in page: SFSafariPage,
                                          userInfo: [String: Any]? = nil,
                                          validationHandler: @escaping (Bool, String?) -> Void)
    {
        page.getPropertiesWithCompletionHandler { props in
            // Use the existing preference as a gatekeeper
            let showItem = !Preferences.main.showInMenu

            // Try to extract the URL and domain
            if let url = props?.url, let domain = self.getDomain(from: url) {
                let matched = Whitelist.main.matches(domain: domain)
                let title = matched
                    ? String(localized: "Hide Comments", comment: "Context menu item title")
                    : String(localized: "Show Comments", comment: "Context menu item title")
                validationHandler(showItem, title)
            } else {
                // Fallback if URL/domain aren't available: show a default title.
                validationHandler(showItem, String(localized: "Toggle Comments", comment: "Context menu item title"))
            }
        }
    }
}

func showError(_: Error) {}
