//
//  SwiftPackage.swift
//  LicensePlistCore
//
//  Created by Matthias Buchetics on 20.09.19.
//

import Foundation

public struct SwiftPackage: Decodable, Equatable {
    struct State: Decodable, Equatable {
        let branch: String?
        let revision: String?
        let version: String?
    }

    let identity: String
    let location: URL
    let state: State
}

extension SwiftPackage: Library {
    public var version: String? { state.version }
    public var name: String { identity }
    public var nameSpecified: String? { nil }
}

extension SwiftPackage: CustomStringConvertible {
    public var description: String {
        return "name: \(name), nameSpecified: \(nameSpecified ?? ""), version: \(version ?? "")"
    }
}

private struct ResolvedPackages: Decodable {
    let pins: [SwiftPackage]
    let version: Int
}

extension SwiftPackage {

    static func loadPackages(_ content: String) -> [SwiftPackage] {
        guard let data = content.data(using: .utf8) else { return [] }
        guard let resolvedPackages = try? JSONDecoder().decode(ResolvedPackages.self, from: data) else { return [] }

        return resolvedPackages.pins
    }

    func toGitHub(renames: [String: String]) -> GitHub? {
        guard location.absoluteString.contains("github.com") else { return nil }

        let urlParts = location.absoluteString
            .replacingOccurrences(of: "https://", with: "")
            .replacingOccurrences(of: "http://", with: "")
            .components(separatedBy: "/")

        let name = urlParts.last?.deletingSuffix(".git") ?? ""
        let owner: String
        if urlParts.count >= 3 {
            owner = urlParts[urlParts.count - 2]
        } else {
            owner = urlParts.first?.components(separatedBy: ":").last ?? ""
        }

        return GitHub(name: name,
                      nameSpecified: renames[name] ?? identity,
                      owner: owner,
                      version: state.version)
    }
}
