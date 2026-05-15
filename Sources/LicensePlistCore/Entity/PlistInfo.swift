import Foundation

struct PlistInfo {
    let options: Options
    var manualLicenses: [ManualLicense]?
    var swiftPackages: [SwiftPackage]?
    var swiftPackageLicenses: [SwiftPackageLicense]?
    var summary: String?
    var summaryPath: URL?
    var licenses: [LicenseInfo]?

    init(options: Options) {
        self.options = options
    }

    mutating func loadSwiftPackageLibraries(packageFiles: [String]) {
        Logger.info("Swift Package Manager License collect start")
        swiftPackages = packageFiles.flatMap { SwiftPackage.loadPackages($0) }
    }

    mutating func loadCachedSwiftPackageLicenses() {
        guard let swiftPackages = swiftPackages, let checkoutsDir = options.packageCheckoutsPath else {
            return
        }

        do {
            swiftPackageLicenses = try SwiftPackageLicense.find(atCheckoutDir: checkoutsDir, for: swiftPackages)
        } catch { fatalError(error.localizedDescription) }
    }

    mutating func loadManualLibraries() {
        Logger.info("Manual License start")
        manualLicenses = ManualLicense.load(options.config.manuals).sorted()
    }

    mutating func compareWithLatestSummary() {
        guard let swiftPackages = swiftPackages,
            let manualLicenses = manualLicenses else { preconditionFailure() }

        let config = options.config

        let contents = (swiftPackages.map { String(describing: $0) } +
            manualLicenses.map { String(describing: $0) } +
            ["add-version-numbers: \(options.config.addVersionNumbers)", "LicensePlist Version: \(Consts.version)"])
            .joined(separator: "\n\n")
        let savePath = options.outputPath.appendingPathComponent("\(options.prefix).latest_result.txt")
        if let previous = savePath.lp.read(), previous == contents, !config.force {
            Logger.warning("Completed because no diff. You can execute force by `--force` flag.")
            exit(0)
        }
        summary = contents
        summaryPath = savePath
    }

    mutating func collectLicenseInfos() {
        guard let swiftLicenses = swiftPackageLicenses,
            let manualLicenses = manualLicenses else { preconditionFailure() }

        licenses = ((swiftLicenses as [LicenseInfo]) + (manualLicenses as [LicenseInfo]))
            .reduce([String: LicenseInfo]()) { sum, e in
                var sum = sum
                sum[e.name] = e
                return sum
            }.values
            .sorted { $0.name.lowercased() < $1.name.lowercased() }
    }

    func outputPlist() {
        guard let licenses = licenses else { preconditionFailure() }
        let outputPath = options.outputPath
        let itemsPath = outputPath.appendingPathComponent(options.prefix)
        if itemsPath.lp.deleteIfExits() {
            Logger.info("Deleted exiting plist within \(options.prefix)")
        }
        itemsPath.lp.createDirectory()
        Logger.info("Directory created: \(outputPath)")

        let holder = options.config.singlePage ?
            LicensePlistHolder.loadAllToRoot(licenses: licenses) :
            LicensePlistHolder.load(licenses: licenses, options: options)
        holder.write(to: outputPath.appendingPathComponent("\(options.prefix).plist"), itemsPath: itemsPath)

        if let markdownPath = options.markdownPath {
            let markdownHolder = LicenseMarkdownHolder.load(licenses: licenses, options: options)
            markdownHolder.write(to: markdownPath)
        }

        if let htmlPath = options.htmlPath {
            let htmlHolder = LicenseHTMLHolder.load(licenses: licenses, options: options)
            htmlHolder.write(to: htmlPath)
        }
    }

    func reportMissings() {
        guard let swiftPackages = swiftPackages, let licenses = licenses else { preconditionFailure() }

        Logger.info("----------Result-----------")
        Logger.info("# Missing license:")
        let missingSwiftPackages = Set(swiftPackages.map(\.name)).subtracting(Set(licenses.map(\.name)))

        let missing = missingSwiftPackages.subtracting(Set(options.config.excludes))
        if missing.isEmpty {
            Logger.info("None 🎉")
            return
        }

        missing.sorted().forEach { Logger.warning($0) }
        if options.config.failIfMissingLicense {
            exit(1)
        }
    }

    func finish() {
        precondition(swiftPackages != nil && licenses != nil)
        guard let summary = summary, let summaryPath = summaryPath else {
            fatalError("summary should be set")
        }
        do {
            try summary.write(to: summaryPath, atomically: true, encoding: Consts.encoding)
        } catch let e {
            Logger.error("Failed to save summary. Error: \(String(describing: e))")
        }
    }
}
