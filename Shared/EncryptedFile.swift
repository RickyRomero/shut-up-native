//
//  EncryptedFile.swift
//  shutup
//
//  Created by Ricky Romero on 5/13/20.
//  Copyright © 2020 Ricky Romero. All rights reserved.
//

import Foundation

struct EncryptedFile {
    let fsPath: URL
    let bundleOrigin: URL

    func read() throws -> Data {
        return Data()
    }

    func write(data contents: Data) throws {
        
    }
}
