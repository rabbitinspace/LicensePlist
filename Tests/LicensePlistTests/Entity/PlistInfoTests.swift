import Foundation
import XCTest
@testable import LicensePlistCore

class PlistInfoTests: XCTestCase {

    override class func setUp() {
        super.setUp()
    }

    private let options = Options(outputPath: URL(fileURLWithPath: "test_result_dir"),
                                  cartfilePath: URL(fileURLWithPath: "test_result_dir"),
                                  mintfilePath: URL(fileURLWithPath: "test_result_dir"),
                                  podsPath: URL(fileURLWithPath: "test_result_dir"),
                                  packagePaths: [URL(fileURLWithPath: "test_result_dir")],
                                  packageCheckoutsPath: nil,
                                  xcodeprojPath: URL(fileURLWithPath: "test_result_dir"),
                                  prefix: Consts.prefix,
                                  gitHubToken: nil,
                                  htmlPath: nil,
                                  markdownPath: nil,
                                  config: Config(                                           manuals: [], excludes: ["exclude"],
                                                 renames: ["Himotoki": "Himotoki2"]))

    func testCompareWithLatestSummary() {
        var target = PlistInfo(options: options)
        target.manualLicenses = []
        target.swiftPackages = []

        XCTAssertNil(target.summary)
        XCTAssertNil(target.summaryPath)
        target.compareWithLatestSummary()

        XCTAssertEqual(target.summary,
                       "add-version-numbers: false\n\nLicensePlist Version: 3.13.0")
        XCTAssertNotNil(target.summaryPath)
    }

    func testCollectLicenseInfos() throws {
        var target = PlistInfo(options: options)
        let manual = Manual(name: "FooBar", source: "https://foo.bar", nameSpecified: nil, version: nil)
        let manualLicense = ManualLicense(library: manual,
                                          body: "body")
        
        let swiftPackage = SwiftPackage(identity: "Example",
                                        location: URL(string: "https://github.com/example/example.git")!,
                                        state: .init(branch: nil,
                                                     revision: nil,
                                                     version: "1.2.2"))
        let swiftPackageLicense = SwiftPackageLicense(name: swiftPackage.name, library: swiftPackage, body: "Do whatever you want")
        
        target.manualLicenses = [manualLicense]
        target.swiftPackageLicenses = [swiftPackageLicense]

        XCTAssertNil(target.licenses)
        target.collectLicenseInfos()
        let licenses = try XCTUnwrap(target.licenses)
        XCTAssertEqual(licenses.count, 2)
        let license = licenses.last
        XCTAssertEqual(license?.name, "FooBar")
    }

    func testReportMissings() {
        var target = PlistInfo(options: options)
        let swiftPackage = SwiftPackage(identity: "Example",
                                        location: URL(string: "https://github.com/example/example.git")!,
                                        state: .init(branch: nil,
                                                     revision: nil,
                                                     version: "1.2.2"))
        let swiftPackageLicense = SwiftPackageLicense(name: swiftPackage.name, library: swiftPackage, body: "Do whatever you want")
        
        target.swiftPackages = [swiftPackage]
        target.licenses = [swiftPackageLicense]
        target.reportMissings()
    }

}
