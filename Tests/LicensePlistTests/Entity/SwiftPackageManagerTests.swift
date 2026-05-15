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

}
