//
//  Setup.swift
//  shutup
//
//  Created by Ricky Romero on 10/6/19.
//  See LICENSE.md for license information.
//

import Cocoa

final class Setup {
    static var main = Setup()
    private init() {}

    // Safari extensions initialize and run in a way that's very unpredictable,
    // so we need some guarantee that this code runs once and only once per process.
    // https://forums.developer.apple.com/thread/113010#420523
    private var bootstrapStarted = false
    private var bootstrapAttempted = false

    func bootstrap(completionHandler: @escaping () -> Void) {
        bootstrap(false, completionHandler: completionHandler)
    }

    func bootstrap(_ resetKeyHeld: Bool, completionHandler: @escaping () -> Void) {
        guard !bootstrapStarted else { return }
        bootstrapStarted = true

        if Info.isApp {
            if queryAvailableSpace() < 200 * 1000 * 1000 { // 200 MB
                showError(FileError.checkingFreeSpace)
            }

            if resetKeyHeld {
                confirmReset()
            }
        }

        Preferences.main.setDefaults()
        Crypto.main.bootstrap()

        bootstrapAttempted = true
        completionHandler()
    }

    func restart() {
        // Prevent a case where multiple things could try to reset at once,
        // kicking off multiple bootstrap sessions
        guard bootstrapAttempted else { return }

        bootstrapStarted = false
        bootstrapAttempted = false
        bootstrap {}
    }

    func confirmReset() {
        let alert = NSAlert()
        alert.alertStyle = .critical
        alert.messageText = "Reset Shut Up?"
        alert.informativeText = "Resetting Shut Up will delete your settings and allowlist. This will restore its original configuration. You cannot undo this action."
        let quitButton = alert.addButton(withTitle: "Quit")
        quitButton.keyEquivalent = ""
        alert.addButton(withTitle: "Reset Shut Up")

        let decision = alert.runModal()

        if decision == .alertFirstButtonReturn {
            NSApp.terminate(nil)
        } else {
            reset()
        }
    }

    func reset() {
        try? Crypto.main.clear(preCatalinaItems: true)
        try? Crypto.main.clear()
        Preferences.main.reset()
        Whitelist.main.reset()
        Stylesheet.main.reset()

        // Relaunch the app and stop this instance
        let resourceUrl = Bundle.main.resourceURL
        let appBundleUrl = resourceUrl?.deletingLastPathComponent().deletingLastPathComponent()

        let config = NSWorkspace.OpenConfiguration()
        config.activates = true
        config.createsNewApplicationInstance = true
        NSWorkspace.shared.openApplication(
            at: appBundleUrl!,
            configuration: config,
            completionHandler: nil
        )

        DispatchQueue.main.async {
            NSApp.terminate(self)
        }
    }

    func queryAvailableSpace() -> Int64 {
        let targetLocation = Info.containerUrl
        let values = try! targetLocation.resourceValues(forKeys: [.volumeAvailableCapacityForImportantUsageKey])
        return values.volumeAvailableCapacityForImportantUsage!
    }
}
