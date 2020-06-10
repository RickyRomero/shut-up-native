//
//  Stylesheet.swift
//  shutup
//
//  Created by Ricky Romero on 5/22/20.
//  Copyright © 2020 Ricky Romero. All rights reserved.
//

import Foundation

class Stylesheet {
    static var main = Stylesheet()
    private init() {}

    private var waitingForResponse = false
    private var completionHandler: ((Error?) -> Void)?

    private let file = EncryptedFile(
        fsPath: Info.localCssUrl,
        bundleOrigin: Bundle.main.url(forResource: "shutup", withExtension: "css")!
    )

    func update(force: Bool, completionHandler: @escaping (Error?) -> Void) {
        guard waitingForResponse == false else { return }

        waitingForResponse = true
        self.completionHandler = completionHandler
        let stylesheetUrl = URL(string: "https://rickyromero.com/shutup/updates/shutup.css")!

        let sessionConfig = URLSessionConfiguration.ephemeral
        sessionConfig.httpAdditionalHeaders = [
            "User-Agent": "\(Info.productName)/\(Info.version) (\(Info.buildNum))",
            "Referer": "Nunya"
        ]
        sessionConfig.timeoutIntervalForRequest = 5 // seconds
        sessionConfig.timeoutIntervalForRequest = 10 // seconds

        let session = URLSession(configuration: sessionConfig)
        let sessionTask = session.dataTask(with: stylesheetUrl, completionHandler: handleServerResponse(data:response:error:))

        sessionTask.resume()
    }

    func handleServerResponse(data: Data?, response: URLResponse?, error: Error?) {
        defer {
            waitingForResponse = false
            DispatchQueue.main.async {
                self.completionHandler?(error != nil ? NetworkingError.interpretingResponse : nil)
                self.completionHandler = nil
            }
        }

        print("Received response from server")
        guard error == nil else {
            print(error!)
            return
        }

        guard data != nil else {
            print("No data received from request.")
            return
        }

        print(String(data: data!, encoding: .utf8)!)
    }
}
