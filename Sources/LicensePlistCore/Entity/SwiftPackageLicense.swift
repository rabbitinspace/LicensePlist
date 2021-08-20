import Foundation

struct SwiftPackageLicense: License, Equatable {
    public let library: SwiftPackage
    public let body: String
}

extension SwiftPackageLicense {
    public enum SearchError: Error {
        case resourceReadFiled(URL)
    }
    
    public static func find(atCheckoutDir dir: URL, for packages: [SwiftPackage]) throws -> [SwiftPackageLicense] {
        var licenses = [SwiftPackageLicense]()
        let reponames = Dictionary(uniqueKeysWithValues: packages.map({ ($0.repositoryURL.lastPathComponent.deletingSuffix(".git"), $0) }))
        let packages = Dictionary(uniqueKeysWithValues: packages.map({ ($0.name, $0) }))
        for subdir in try FileManager.default.contentsOfDirectory(atPath: dir.path) {
            let subdirURL = dir.appendingPathComponent(subdir)
            var isDir: ObjCBool = false
            
            guard let package = packages[subdir] ?? reponames[subdir] else { continue }
            guard FileManager.default.fileExists(atPath: subdirURL.path, isDirectory: &isDir), isDir.boolValue else { continue }
            
            for item in try FileManager.default.contentsOfDirectory(atPath: subdirURL.path) {
                guard isLicense(name: item) else { continue }
                
                let itemURL = subdirURL.appendingPathComponent(item)
                licenses.append(contentsOf: try readLicenses(at: itemURL, for: package))
                break
            }
        }
        
        return licenses
    }
}

private func isLicense(name: String) -> Bool {
    let lower = name.lowercased()
    guard lower.starts(with: "license") || lower.starts(with: "licence") else {
        return false
    }
    
    // check if there's a file extension next
    let next = lower.dropFirst(7)  // drop "license" or "licence"
    if next.isEmpty {
        return true  // no file extension, it's a license file
    }
    
    if next.first != "." {
        return false  // no file extension, it's not a license file
    }
    
    return true
}

private func readLicenses(at path: URL, for package: SwiftPackage) throws -> [SwiftPackageLicense] {
    var isDir: ObjCBool = false
    guard FileManager.default.fileExists(atPath: path.path, isDirectory: &isDir) else { return [] }
    
    guard isDir.boolValue else {
        let body = try String(contentsOfFile: path.path)
        return [SwiftPackageLicense(library: package, body: body)]
    }
    
    var licenses = [SwiftPackageLicense]()
    for item in try FileManager.default.contentsOfDirectory(atPath: path.path) {
        guard isLicense(name: item) else { continue }
        
        let comps = item.split(separator: ".")
        guard comps.count > 1 else { continue }
        
        let suffix = comps[1...].joined(separator: ".")
        let package = SwiftPackage(package: suffix, repositoryURL: package.repositoryURL, state: package.state)
        let body = try String(contentsOfFile: path.appendingPathComponent(item).path)
        licenses.append(SwiftPackageLicense(library: package, body: body))
    }
    
    return licenses
}
