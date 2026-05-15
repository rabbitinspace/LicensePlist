import Foundation
import XCTest
@testable import LicensePlistCore

class URLExtensionTests: XCTestCase {
    func testFileURL() throws {
        let url = try XCTUnwrap(URL(string: "/github.com/mono0926/LicensePlist"))
        XCTAssertEqual(url.lp.fileURL.absoluteString, "file:///github.com/mono0926/LicensePlist")
    }
}
