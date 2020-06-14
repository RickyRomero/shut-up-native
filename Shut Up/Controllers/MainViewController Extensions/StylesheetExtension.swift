//
//  Stylesheet.swift
//  Shut Up
//
//  Created by Ricky Romero on 6/14/20.
//  Copyright © 2020 Ricky Romero. All rights reserved.
//

import Cocoa

extension MainViewController {
    func resetCssLabelUpdateTimer() {
        cssLabelUpdateTimer?.invalidate()
        cssLabelUpdateTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            DispatchQueue.main.async {
                self.updateLastCssUpdateLabel()
            }
        }
    }

    func updateLastCssUpdateLabel() {
        let timestamp = Preferences.main.lastStylesheetUpdate
        updateLastCssUpdateLabel(with: timestamp)
    }

    func updateLastCssUpdateLabel(with timestamp: Date) {
        let cutoff: Double = 60 * 60 * 24 * 7
        let cutoffDate = Date(timeIntervalSinceNow: cutoff * -1.0)
        let relativeTimeStr: String!

        if timestamp < cutoffDate {
            relativeTimeStr = "Updated over 1 week ago"
        } else {
            relativeTimeStr = "Updated \(timestamp.relativeTime)"
        }

        lastCssUpdateLabel.stringValue = relativeTimeStr
    }

    @IBAction func forceStylesheetUpdate(_ sender: NSButton) {
        print("Should be fetching now")
        Stylesheet.main.update(force: false) { error in
            guard error == nil else { return /* and display the error */ }
            let now = Date()
            Preferences.main.lastStylesheetUpdate = now
            self.updateLastCssUpdateLabel(with: now)
            self.resetCssLabelUpdateTimer()
        }
    }
}
