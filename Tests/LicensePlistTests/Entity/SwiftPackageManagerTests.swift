//
//  SwiftPackageManagerTests.swift
//  APIKit
//
//  Created by Matthias Buchetics on 20.09.19.
//

import Foundation
import XCTest
@testable import LicensePlistCore

class SwiftPackageManagerTests: XCTestCase {

    func testDecoding() throws {
        let jsonString = """
            {
              "identity": "APIKit",
              "location": "https://github.com/ishkawa/APIKit.git",
              "state": {
                "branch": null,
                "revision": "86d51ecee0bc0ebdb53fb69b11a24169a69097ba",
                "version": "4.1.0"
              }
            }
        """

        let data = try XCTUnwrap(jsonString.data(using: .utf8))
        let package = try JSONDecoder().decode(SwiftPackage.self, from: data)

        XCTAssertEqual(package.identity, "APIKit")
        XCTAssertEqual(package.location, URL(string: "https://github.com/ishkawa/APIKit.git"))
        XCTAssertEqual(package.state.revision, "86d51ecee0bc0ebdb53fb69b11a24169a69097ba")
        XCTAssertEqual(package.state.version, "4.1.0")
    }

    func testDecodingOfURLWithDots() throws {
        let jsonString = """
            {
              "identity": "R.swift.Library",
              "location": "https://github.com/mac-cain13/R.swift.Library",
              "state": {
                "branch": "master",
                "revision": "3365947d725398694d6ed49f2e6622f05ca3fc0f",
                "version": null
              }
            }
        """

        let data = try XCTUnwrap(jsonString.data(using: .utf8))
        let package = try JSONDecoder().decode(SwiftPackage.self, from: data)

        XCTAssertEqual(package.identity, "R.swift.Library")
        XCTAssertEqual(package.location, URL(string: "https://github.com/mac-cain13/R.swift.Library"))
        XCTAssertEqual(package.state.revision, "3365947d725398694d6ed49f2e6622f05ca3fc0f")
        XCTAssertEqual(package.state.version, nil)
    }

    func testDecodingOptionalVersion() throws {
        let jsonString = """
            {
              "identity": "APIKit",
              "location": "https://github.com/ishkawa/APIKit.git",
              "state": {
                "branch": "master",
                "revision": "86d51ecee0bc0ebdb53fb69b11a24169a69097ba",
                "version": null
              }
            }
        """

        let data = try XCTUnwrap(jsonString.data(using: .utf8))
        let package = try JSONDecoder().decode(SwiftPackage.self, from: data)

        XCTAssertEqual(package.identity, "APIKit")
        XCTAssertEqual(package.location, URL(string: "https://github.com/ishkawa/APIKit.git"))
        XCTAssertEqual(package.state.revision, "86d51ecee0bc0ebdb53fb69b11a24169a69097ba")
        XCTAssertEqual(package.state.branch, "master")
        XCTAssertEqual(package.state.version, nil)
    }

    func testConvertToGithub() {
        let package = SwiftPackage(identity: "Commander",
                                   location: URL(string: "https://github.com/kylef/Commander.git")!,
                                   state: SwiftPackage.State(branch: nil, revision: "e5b50ad7b2e91eeb828393e89b03577b16be7db9", version: "0.8.0"))
        let result = package.toGitHub(renames: [:])
        XCTAssertEqual(result, GitHub(name: "Commander", nameSpecified: "Commander", owner: "kylef", version: "0.8.0"))
    }

    func testConvertToGithubNameWithDots() {
        let package = SwiftPackage(identity: "R.swift.Library",
                                   location: URL(string: "https://github.com/mac-cain13/R.swift.Library")!,
                                   state: SwiftPackage.State(branch: nil, revision: "3365947d725398694d6ed49f2e6622f05ca3fc0f", version: nil))
        let result = package.toGitHub(renames: [:])
        XCTAssertEqual(result, GitHub(name: "R.swift.Library", nameSpecified: "R.swift.Library", owner: "mac-cain13", version: nil))
    }

    func testConvertToGithubSSH() {
        let package = SwiftPackage(identity: "LicensePlist",
                                   location: URL(string: "git@github.com:mono0926/LicensePlist.git")!,
                                   state: SwiftPackage.State(branch: nil, revision: "3365947d725398694d6ed49f2e6622f05ca3fc0e", version: nil))
        let result = package.toGitHub(renames: [:])
        XCTAssertEqual(result, GitHub(name: "LicensePlist", nameSpecified: "LicensePlist", owner: "mono0926", version: nil))
    }

    func testConvertToGithubPackageName() {
        let package = SwiftPackage(identity: "IterableSDK",
                                   location: URL(string: "https://github.com/Iterable/swift-sdk")!,
                                   state: SwiftPackage.State(branch: nil, revision: "3365947d725398694d6ed49f2e6622f05ca3fc0e", version: nil))
        let result = package.toGitHub(renames: [:])
        XCTAssertEqual(result, GitHub(name: "swift-sdk", nameSpecified: "IterableSDK", owner: "Iterable", version: nil))
    }

    func testConvertToGithubRenames() {
        let package = SwiftPackage(identity: "IterableSDK",
                                   location: URL(string: "https://github.com/Iterable/swift-sdk")!,
                                   state: SwiftPackage.State(branch: nil, revision: "3365947d725398694d6ed49f2e6622f05ca3fc0e", version: nil))
        let result = package.toGitHub(renames: ["swift-sdk": "NAME"])
        XCTAssertEqual(result, GitHub(name: "swift-sdk", nameSpecified: "NAME", owner: "Iterable", version: nil))
    }

    func testRename() {
        let package = SwiftPackage(identity: "Commander",
                                   location: URL(string: "https://github.com/kylef/Commander.git")!,
                                   state: SwiftPackage.State(branch: nil,
                                                             revision: "e5b50ad7b2e91eeb828393e89b03577b16be7db9", version: "0.8.0"))
        let result = package.toGitHub(renames: ["Commander": "RenamedCommander"])
        XCTAssertEqual(result, GitHub(name: "Commander", nameSpecified: "RenamedCommander", owner: "kylef", version: "0.8.0"))
    }

    func testInvalidURL() {
        let package = SwiftPackage(identity: "Google", location: URL(string: "http://www.google.com")!, state: SwiftPackage.State(branch: nil, revision: "", version: "0.0.0"))
        let result = package.toGitHub(renames: [:])
        XCTAssertNil(result)
    }

    func testNonGithub() {
        let package = SwiftPackage(identity: "Bitbucket",
                                   location: URL(string: "https://mbuchetics@bitbucket.org/mbuchetics/adventofcode2018.git")!,
                                   state: SwiftPackage.State(branch: nil, revision: "", version: "0.0.0"))
        let result = package.toGitHub(renames: [:])
        XCTAssertNil(result)
    }

    func testParse() throws {
        let path = "https://raw.githubusercontent.com/mono0926/LicensePlist/master/Package.resolved"
        // let path = "https://raw.githubusercontent.com/mono0926/LicensePlist/master/Tests/LicensePlistTests/Resources/Package.resolved"
        let content = try String(contentsOf: XCTUnwrap(URL(string: path)))
        let packages = SwiftPackage.loadPackages(content)

        XCTAssertFalse(packages.isEmpty)
        XCTAssertEqual(packages.count, 11)

        let packageFirst = try XCTUnwrap(packages.first)
        XCTAssertEqual(packageFirst, SwiftPackage(identity: "apikit",
                                                  location: URL(string: "https://github.com/ishkawa/APIKit.git")!,
                                                  state: SwiftPackage.State(branch: nil, revision: "4e7f42d93afb787b0bc502171f9b5c12cf49d0ca", version: "5.3.0")))
        let packageLast = try XCTUnwrap(packages.last)
        XCTAssertEqual(packageLast, SwiftPackage(identity: "yams",
                                                 location: URL(string: "https://github.com/jpsim/Yams.git")!,
                                                 state: SwiftPackage.State(branch: nil, revision: "f47ba4838c30dbd59998a4e4c87ab620ff959e8a", version: "5.0.5")))

    }
}
