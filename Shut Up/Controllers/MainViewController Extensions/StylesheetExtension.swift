//
//  StylesheetExtension.swift
//  Shut Up
//
//  Created by Ricky Romero on 6/14/20.
//  See LICENSE.md for license information.
//

import Cocoa

var autoIconStr: NSAttributedString?
var manualIconStr: NSAttributedString?

extension MainViewController {
    func makeIconStr(for updateMethod: String) -> NSAttributedString {
        let symbol = NSImage(
            systemSymbolName: updateMethod == "auto" ? "a.circle.fill" : "m.circle.fill",
            accessibilityDescription: updateMethod == "auto" ? "Automatically" : "Manually"
        )

        let attachment = NSTextAttachment()
        attachment.image = symbol

        return NSAttributedString(attachment: attachment)
    }

    func setUpSymbols() {
        super.viewDidLoad()

        autoIconStr = makeIconStr(for: "auto")
        manualIconStr = makeIconStr(for: "manual")
    }

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
        let instantDuration: Double = 15
        let instantDurationDate = Date(timeIntervalSinceNow: instantDuration * -1.0)
        let cutoff: Double = 60 * 60 * 24 * 7
        let cutoffDate = Date(timeIntervalSinceNow: cutoff * -1.0)
        let relativeFormatter = RelativeDateTimeFormatter()
        let absoluteFormatter = DateFormatter()
        let updatedHow = Preferences.main.lastUpdateMethod == "automatic" ? "Automatically" : "Manually"
        let iconStr = Preferences.main.lastUpdateMethod == "automatic" ? autoIconStr : manualIconStr

        relativeFormatter.unitsStyle = .full
        absoluteFormatter.dateStyle = .medium
        absoluteFormatter.timeStyle = .medium

        let relativeStr = relativeFormatter.localizedString(for: timestamp, relativeTo: Date())
        let absoluteStr = absoluteFormatter.string(from: timestamp)

        let summaryStr = {
            if timestamp == Date(timeIntervalSince1970: 0) {
                return "--"
            } else if timestamp > instantDurationDate {
                return "Updated just now"
            } else if timestamp < cutoffDate {
                return "Updated over 1 week ago"
            } else {
                return "Updated \(relativeStr)"
            }
        }()

        let explanationStr = timestamp == Date(timeIntervalSince1970: 0) ?
            "Stylesheet hasn't been updated." :
            "\(updatedHow) updated on \(absoluteStr)."

        let textStr = NSAttributedString(string: summaryStr)

        // Combine SF Symbol icon string with summary
        let labelString = NSMutableAttributedString()
        if let iconStr = iconStr {
            labelString.append(iconStr)
            labelString.append(NSAttributedString(string: " "))
        }
        labelString.append(textStr)

        lastCssUpdateLabel.attributedStringValue = labelString
        lastCssUpdateLabel.toolTip = explanationStr
    }

    @IBAction func forceStylesheetUpdate(_ sender: NSButton) {
        sender.isEnabled = false
        lastCssUpdateLabel.isHidden = true
        updatingSpinner.startAnimation(nil)
        updatingIndicator.isHidden = false
        Stylesheet.main.update(force: true) { error in
            sender.isEnabled = true
            self.lastCssUpdateLabel.isHidden = false
            self.updatingIndicator.isHidden = true
            self.updatingSpinner.stopAnimation(nil)

            guard error == nil else {
                showError(error!)
                return
            }

            self.updateLastCssUpdateLabel(with: Preferences.main.lastStylesheetUpdate)
            self.resetCssLabelUpdateTimer()
        }
    }
}
