//
//  LockFile.swift
//  shutup
//
//  Created by Ricky Romero on 5/16/20.
//  See LICENSE.md for license information.
//

import Foundation

final class LockFile {
    private var url: URL
    private var claimedDate: Date?
    private let queue: DispatchQueue!
    var expiry = 120 // seconds

    init(url: URL) {
        self.url = url
        queue = DispatchQueue(label: "\(Info.bundleId).\(url.lastPathComponent)")
    }

    func attempt() -> Bool {
        let claimed = FileManager.default.createFile(
            atPath: url.path,
            contents: Data(),
            attributes: [.immutable: 1]
        )
        if claimed { claimedDate = lockDate }
        return claimed
    }

    func unlock() {
        guard claimedByUs else { return }
        smash()
    }

    func smash() { // Forcefully remove the lock
        claimedDate = nil
        try? FileManager.default.setAttributes([.immutable: 0], ofItemAtPath: url.path)
        try? FileManager.default.removeItem(at: url)
    }

    var lockDate: Date? {
        let attributes = try? FileManager.default.attributesOfItem(atPath: url.path)
        return attributes?[.creationDate] as? Date
    }

    private var claimedByUs: Bool { lockDate == claimedDate && lockDate != nil }
    private var timerActive = false
    private var lockExpired: Bool {
        let negativeExpiry = Double(expiry) * -1
        let age = lockDate?.timeIntervalSinceNow
        guard age != nil else { return false }
        return age! < negativeExpiry
    }

    func claim() {
        guard !timerActive else { return }
        timerActive = true

        var pollingTask: DispatchWorkItem
        pollingTask = DispatchWorkItem {
            while true {
                let lockClaimed = self.attempt()
                if lockClaimed {
                    break
                } else {
                    if self.lockExpired {
                        self.smash()
                    }

                    usleep(1000 * 1000 / 2)
                }
            }
        }

        queue.sync(execute: pollingTask)
    }
}
