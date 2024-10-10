//
//  AuthProvider.swift
//  BackendService
//
//  Created by Patrick Kladek on 10.10.24.
//

import Foundation
import KeychainAccess

// MARK: - AuthProvider

public struct AuthProvider {

    // MARK: Static Properties

    public static let shared = AuthProvider()

    static let service = "sa.hudhud.map"

    // MARK: Lifecycle

    private init() {}

    // MARK: Functions

    public func store(credentials: Credentials) throws {
        let keychain = Keychain(service: Self.service)
            .synchronizable(true)

        let data = try JSONEncoder().encode(credentials)
        keychain[data: Credentials.key] = data
    }

    public func retrive() throws -> Credentials? {
        let keychain = Keychain(service: Self.service)
        guard let data = keychain[data: Credentials.key] else { return nil }

        return try JSONDecoder().decode(Credentials.self, from: data)
    }
}

// MARK: - Credentials

public struct Credentials: Codable {

    // MARK: Static Properties

    static let key = "credentials"

    // MARK: Properties

    public let accessToken: String
    public let refreshToken: String
    public let expiration: Date

    // MARK: Computed Properties

    public var isExpired: Bool {
        return self.expiration > Date()
    }

    // MARK: Lifecycle

    public init(accessToken: String, refreshToken: String, expiration: Date) {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.expiration = expiration
    }
}
