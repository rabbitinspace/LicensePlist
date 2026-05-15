import Foundation

public final class LicensePlist {

    public init() {}

    public func process(options: Options) {
        Logger.info("Start")
        var info = PlistInfo(options: options)

        do {
            let swiftPackageFileReadResults = try options.packagePaths.compactMap { packagePath in
                try SwiftPackageFileReader(path: packagePath).read()
            }
            let xcodeProjectFileReadResult = try XcodeProjectFileReader(path: options.xcodeprojPath).read()
            info.loadSwiftPackageLibraries(
                packageFiles: swiftPackageFileReadResults.isEmpty
                    ? [xcodeProjectFileReadResult ?? ""]
                    : swiftPackageFileReadResults
            )
        } catch {
            fatalError(error.localizedDescription)
        }
        info.loadManualLibraries()
        info.compareWithLatestSummary()
        info.loadCachedSwiftPackageLicenses()
        info.collectLicenseInfos()
        info.outputPlist()
        Logger.info("End")
        info.reportMissings()
        info.finish()
        if !options.config.suppressOpeningDirectory {
            Shell.open(options.outputPath.path)
        }
    }
}

private func readPodsAcknowledgements(path: URL) -> [String] {
    if path.lastPathComponent != Consts.podsDirectoryName {
        fatalError("Invalid Pods name: \(path.lastPathComponent)")
    }

    let pathsToFind = [
        path.appendingPathComponent("Target Support Files"),
        path.appendingPathComponent("_Prebuild").appendingPathComponent("Target Support Files")
    ]

    let paths = pathsToFind.filter { $0.lp.isExists }
    if paths.isEmpty {
        pathsToFind.forEach { Logger.warning("not found: \($0)") }
        return []
    }
    let urls = paths.flatMap { $0.lp.listDir() }
        .filter { $0.lp.isDirectory }
        .map { f in
            f.lp.listDir()
                .filter { $0.lastPathComponent.hasSuffix("-acknowledgements.plist") }
        }.flatMap { $0 }
    urls.forEach { Logger.info("Pod acknowledgements found: \($0.lastPathComponent)") }
    return urls.map { $0.lp.read() }.compactMap { $0 }
}
