import Foundation
@testable import LicensePlistCore

class TestUtil {

    static var sourceDir: URL {
        return URL(string: #file)!
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
    }

    static var testResourceDir: URL {
        return sourceDir
            .appendingPathComponent("Tests")
            .appendingPathComponent("LicensePlistTests")
            .appendingPathComponent("Resources")
    }

    static var testProjectsPath: URL {
        return sourceDir
            .appendingPathComponent("Tests")
            .appendingPathComponent("LicensePlistTests")
            .appendingPathComponent("XcodeProjects")
    }

}
