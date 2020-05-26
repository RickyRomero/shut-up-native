//
//  LockFile.swift
//  shutup
//
//  Created by Ricky Romero on 5/16/20.
//  Copyright © 2020 Ricky Romero. All rights reserved.
//

import Foundation

final class LockFile {
    private var url: URL
    private var claimedDate: Date?
    private var timerStartedDate: Date?
    var expiry = 120 // seconds
    var timeout = 150 // seconds

    init(url: URL) {
        self.url = url
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
        destroy()
    }

    func destroy() {
        claimedDate = nil
        try? FileManager.default.setAttributes([.immutable: 0], ofItemAtPath: url.path)
        try? FileManager.default.removeItem(at: url)
    }

    var lockDate: Date? {
        let attributes = try? FileManager.default.attributesOfItem(atPath: url.path)
        return attributes?[.creationDate] as? Date
    }

    private var claimedByUs: Bool { lockDate == claimedDate && lockDate != nil }
    private var timerActive: Bool {
        let negativeTimeout = Double(timeout) * -1
        let timerAge = timerStartedDate?.timeIntervalSinceNow
        guard timerAge != nil else { return false }
        return timerAge! > negativeTimeout
    }
    private var lockExpired: Bool {
        let negativeExpiry = Double(expiry) * -1
        let age = lockDate?.timeIntervalSinceNow
        guard age != nil else { return false }
        return age! < negativeExpiry
    }

    func claim(_ cla: ConditionalLockAction) {
        guard cla.obtainLockAndTakeActionIf() == true else {
            cla.otherwise()
            cla.finally()
            cla.queue?.next()
            return
        }
        guard !timerActive else { return }
        timerStartedDate = Date()

        pollLock(cla)
    }

    private func pollLock(_ cla: ConditionalLockAction) {
        let lockClaimed = attempt()
        if lockClaimed {
            if cla.obtainLockAndTakeActionIf() == true {
                cla.action()
            } else {
                cla.otherwise()
            }

            cla.finally()
            unlock()
            cla.queue?.next()
        } else {
            guard timerActive else {
//                cla.error = LockError.timedOut
                cla.finally()
                cla.queue?.next()
                return
            }
            if lockExpired {
                destroy()
            }

            Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { _ in
                self.pollLock(cla)
            }
        }
    }
}
