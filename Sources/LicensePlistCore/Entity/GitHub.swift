import Foundation
import APIKit
import LoggerAPI

public struct GitHub: Library {
    public let name: String
    public let nameSpecified: String?
    var owner: String
    public let version: String?
    public let cachedPath: URL?
    
    init(name: String, nameSpecified: String?, owner: String, version: String?, cachedPath: URL? = nil) {
        self.name = name
        self.nameSpecified = nameSpecified
        self.owner = owner
        self.version = version
        self.cachedPath = cachedPath
    }
}

extension GitHub {
    public static func==(lhs: GitHub, rhs: GitHub) -> Bool {
        return lhs.name == rhs.name &&
            lhs.nameSpecified == rhs.nameSpecified &&
            lhs.owner == rhs.owner &&
            lhs.version == rhs.version
    }
}

extension GitHub: CustomStringConvertible {
    public var description: String {
        return "name: \(name), nameSpecified: \(nameSpecified ?? ""), owner: \(owner), version: \(version ?? "")"
    }
}

extension GitHub {
    public static func load(_ file: GitHubLibraryConfigFile, renames: [String: String] = [:]) -> [GitHub] {
        let r = load(file, renames: renames, version: true)
        if !r.isEmpty {
            return r
        }
        return load(file, renames: renames, version: false)
    }

    private static func load(_ file: GitHubLibraryConfigFile,
                             renames: [String: String],
                             version: Bool = false) -> [GitHub] {
        guard let content = file.content else { return [] }
        let regexString = file.type.regexString(version: version)
        let regex = try! NSRegularExpression(pattern: regexString, options: [])
        let nsContent = content as NSString
        let matches = regex.matches(in: content, options: [], range: NSRange(location: 0, length: nsContent.length))
        return matches.map { match -> GitHub? in
            let numberOfRanges = match.numberOfRanges
            guard numberOfRanges == (version ? 4 : 3) else {
                assert(false, "maybe invalid regular expression to: \(nsContent.substring(with: match.range))")
                return nil
            }
            let version = { () -> String? in
                guard version else { return nil }
                let version = nsContent.substring(with: match.range(at: 3))
                let pattern = try! NSRegularExpression(pattern: "\\w{40}", options: [])
                if !pattern.matches(in: version, options: [], range: NSRange(location: 0, length: (version as NSString).length)).isEmpty {
                    return String(version.prefix(7))
                }
                return version
            }()
            let name = nsContent.substring(with: match.range(at: 2))
            return GitHub(name: name,
                          nameSpecified: renames[name],
                          owner: nsContent.substring(with: match.range(at: 1)),
                          version: version,
                          cachedPath: Self.findCachedLicense(for: file, name: name))
            }
            .compactMap { $0 }
    }
    
    private static func findCachedLicense(for file: GitHubLibraryConfigFile, name: String) -> URL? {
        guard let caches = file.cachePath else {
            return nil
        }
        
        let empty = URL(fileURLWithPath: "")  // to prevent github calls when cache dir is specified
        let dir = caches.appendingPathComponent(name)
        guard (try? caches.checkResourceIsReachable()) ?? false else {
            return empty
        }
        
        let children = (try? FileManager.default.contentsOfDirectory(
            at: dir,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles, .skipsPackageDescendants]
        )) ?? []
        
        for child in children {
            let name = child.lastPathComponent.lowercased()
            if name.starts(with: "license") || name.starts(with: "licence") {
                return child
            }
        }
        
        return empty
    }
}
