import Foundation

public struct GitHubLibraryConfigFile: Equatable {
    let type: GitHubLibraryConfigFileType
    let content: String?
    let cachePath: URL?
    
    init(type: GitHubLibraryConfigFileType, content: String?, cachePath: URL? = nil) {
        self.type = type
        self.content = content
        self.cachePath = cachePath
    }
}

extension GitHubLibraryConfigFile {
    static func carthage(content: String?, cachePath: URL? = nil) -> GitHubLibraryConfigFile { return .init(type: .carthage, content: content, cachePath: cachePath) }
    static func mint(content: String?) -> GitHubLibraryConfigFile { return .init(type: .mint, content: content, cachePath: nil) }
    static func licensePlist(content: String?) -> GitHubLibraryConfigFile { return .init(type: .licensePlist, content: content, cachePath: nil) }
}

public enum GitHubLibraryConfigFileType: Int, CaseIterable {
    case carthage
    case mint
    case licensePlist
}

extension GitHubLibraryConfigFileType {
    func regexString(version: Bool) -> String {
        let pattern = "[\\w\\.\\-]+"
        switch self {
        case .carthage:
            let quotes = "\""
            return "github \(quotes)(\(pattern))/(\(pattern))\(quotes)" + (version ? " \(quotes)(\(pattern))\(quotes)" : "")
        case .mint:
            return "(\(pattern))/(\(pattern))" + (version ? "@(\(pattern))" : "")
        case .licensePlist:
            return "(\(pattern))/(\(pattern))" + (version ? " (\(pattern))" : "")
        }
    }
}
