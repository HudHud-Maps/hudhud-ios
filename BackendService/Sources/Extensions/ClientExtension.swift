//
//  ClientExtension.swift
//
//
//  Created by Fatima Aljaber on 11/08/2024.
//

import Foundation
import OpenAPIURLSession

extension Client {
    static func makeClient(using baseURLString: String, transport: URLSessionTransport = URLSessionTransport()) -> Client {
        if let baseURL = URL(string: baseURLString) {
            return Client(serverURL: baseURL, transport: transport)
        } else {
            let fallbackURL = URL(string: "https://api.dev.hudhud.sa")! // swiftlint:disable:this force_unwrapping
            return Client(serverURL: fallbackURL, transport: transport)
        }
    }
}
