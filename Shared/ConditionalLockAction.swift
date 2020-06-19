//
//  ConditionalLockAction.swift
//  shutup
//
//  Created by Ricky Romero on 5/18/20.
//  Copyright © 2020 Ricky Romero. All rights reserved.
//

final class ClaQueue {
    init(_ operations: [ConditionalLockAction]) {
        ops = operations
        for index in 0..<ops.count {
            ops[index].queue = self
        }
    }

    func run(_ whenFinished: ((Error?) -> Void)?) {
        onFinish = whenFinished ?? onFinish
        currentOp?.lock.claim(currentOp!)
    }

    func next() {
        if step < ops.count - 1 && currentOp?.error == nil {
            step += 1
            run(nil)
        } else {
            onFinish?(currentOp?.error)
        }
    }

    private var ops: [ConditionalLockAction]
    private var step = 0
    private var currentOp: ConditionalLockAction? { ops[step] }
    private var onFinish: ((Error?) -> Void)?
}

protocol ConditionalLockAction {
    // Which lock should we use to manage the state of this?
    var lock: LockFile { get set }
    var queue: ClaQueue? { get set }
    var error: Error? { get set }

    // A condition which returns true or false depending on
    // whether write operations must happen.
    // This will run again after we obtain the lock, to double-check
    // that said lock is still necessary.
    func obtainLockAndTakeActionIf() -> Bool

    // Code to run should a lock not be necessary.
    func otherwise()

    // What should happen once we've obtained the lock?
    func action()

    // What should happen after this is all done?
    func finally()
}

// Default implementations, to allow for them to be optional
extension ConditionalLockAction {
    func obtainLockAndTakeActionIf() -> Bool { true }
    func otherwise() {}
    func finally() {}
}
