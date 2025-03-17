//
//  SafariExtensionHandler.swift
//  shutup Extension
//
//  Created by Ricky Romero on 9/2/19.
//  See LICENSE.md for license information.
//

import SafariServices

class SafariExtensionHandler: SFSafariExtensionHandler {
    enum ToolbarImages {
        private static let enabledUrl = Bundle.main.urlForImageResource("turn-off")!
        private static let disabledUrl = Bundle.main.urlForImageResource("turn-on")!

        static let enabled = NSImage(contentsOfFile: enabledUrl.path)
        static let disabled = NSImage(contentsOfFile: disabledUrl.path)
    }

    override func beginRequest(with _: NSExtensionContext) {
        Setup.main.bootstrap {}
    }

    override func contextMenuItemSelected(withCommand _: String, in page: SFSafariPage, userInfo _: [String: Any]? = nil) {
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

    private func reloadContentBlocker(times: Int, completion: @escaping () -> Void) {
        guard times > 0 else {
            completion()
            return
        }

        SFContentBlockerManager.reloadContentBlocker(withIdentifier: Info.blockerBundleId) { error in
            guard error == nil else {
                NSLog("com.rickyromero.shutup.blocker helper error: \(error!.localizedDescription)")
                return
            }
            self.reloadContentBlocker(times: times - 1, completion: completion)
        }
    }

    func toggleComments(for window: SFSafariWindow?, with page: SFSafariPage?, having props: SFSafariPageProperties?) {
        guard let domain = getDomain(from: props?.url) else { return }
        _ = Whitelist.main.toggle(domain: domain)

        window?.getToolbarItem { button in
            self.updateIcon(in: button, for: props?.url)
        }

        // WORKAROUND: Safari sometimes fails to apply content blocker updates on the first reload.
        // Reloading 3 times ensures the changes take effect.
        reloadContentBlocker(times: 3) {
            let delay: Int
            #if arch(arm64)
                delay = 75
            #else
                delay = 300
            #endif

            // Reload the page with a short delay (75ms on ARM and 300ms on Intel)
            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(delay)) {
                page?.reload()
            }

            // TODO: Find a better way to handle this.
            let shouldRemove = (
                !Preferences.main.automaticWhitelisting ||
                    (props?.usesPrivateBrowsing ?? false)
            )
            if shouldRemove {
                // WORKAROUND: Unfortunately this also requires an ugly delay...
                DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(1250)) {
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
        let icon = matched ? ToolbarImages.disabled : ToolbarImages.enabled
        button?.setImage(icon)
        button?.setLabel(matched
            ? String(localized: "Hide Comments", comment: "Toolbar button label")
            : String(localized: "Show Comments", comment: "Toolbar button label"))
    }

    override func validateContextMenuItem(withCommand _: String,
                                          in page: SFSafariPage,
                                          userInfo _: [String: Any]? = nil,
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
